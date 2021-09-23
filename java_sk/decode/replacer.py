import re

from ast.visit import visit as v

from ast.node import Node
from ast.body.classorinterfacedeclaration import ClassOrInterfaceDeclaration
from ast.body.variabledeclarator import VariableDeclarator
from ast.expr.integerliteralexpr import IntegerLiteralExpr
from ast.utils.utils import replace_node

from cStringIO import StringIO
from csv import reader as csv_reader

"""
Replacing holes with solutions
"""


class HReplacer(object):

    def __init__(self, output_path, holes):
        self._output = output_path
        self._holes = holes

        self._cur_class = None

        self._sol = {}  # { v : n }

        # hole assignments for roles
        # glblInit_fid__cid_????,StmtAssign,accessor_???? = n
        names = map(lambda n: n.name.encode(), self._holes)
        regex_role = r"({})__(\S+)_\S+ = (\d+)$".format('|'.join(names))

        buffer = StringIO()
        with open(self._output, "r") as f:
            reading = False
            for line in f:
                if line == 'Generating code with CSV\n':
                    reading = True
                    continue
                if line == '[SKETCH] DONE\n':
                    reading = False
                    continue
                if reading:
                    buffer.write(line)

        buffer.seek(0)

        rdr = csv_reader(buffer)

        for row in rdr:
            func, node_type, location, content = row
            if node_type == "StmtAssign":
                reg_result = re.match(regex_role, content)
                if reg_result:
                    field_name, class_name, value = reg_result.group(1), reg_result.group(2), reg_result.group(3)
                    field_name = field_name.decode()
                    class_name = class_name.decode()
                    value = int(value)
                    for hole in self._holes:
                        if hole.name == field_name and hole.class_name == class_name:
                            self._sol[hole] = value

    @v.on("node")
    def visit(self, node):
        """
        This is the generic method to initialize the dynamic dispatcher
        """

    @v.when(Node)
    def visit(self, node):
        for c in node.childrenNodes:
            c.accept(self)

    @v.when(ClassOrInterfaceDeclaration)
    def visit(self, node):
        self._cur_class = node.name
        for c in node.childrenNodes: c.accept(self)

    @v.when(VariableDeclarator)
    def visit(self, node):
        if node in self._sol:
            new_init = IntegerLiteralExpr(lit_value = str(self._sol[node]))
            replace_node(node.init, new_init)
            


# """
# Replacing regex generators with solutions
# """


# class EGReplacer(object):

#     def __init__(self, output_path, egens):
#         self._output = output_path

#         self._cur_mtd = None

#         # assignment appearances
#         self._assigns = {}  # { mtd : exp* }

#         # interpret the synthesis result
#         with open(self._output, 'r') as f:
#             for line in f:
#                 line = line.strip()
#                 try:
#                     items = line.split(',')
#                     func, kind, msg = items[0], items[1], ','.join(items[2:])
#                     if kind == "StmtAssign":
#                         util.mk_or_append(self._assigns, func,
#                                           msg.split('=')[-1].strip())
#                 except IndexError:  # not a line generated by custom codegen
#                     pass  # if "Total time" in line: logging.info(line)

#     @v.on("node")
#     def visit(self, node):
#         """
#         This is the generic method to initialize the dynamic dispatcher
#         """

#     @v.when(Program)
#     def visit(self, node): pass

#     @v.when(Clazz)
#     def visit(self, node): pass

#     @v.when(Field)
#     def visit(self, node): pass

#     @v.when(Method)
#     def visit(self, node):
#         self._cur_mtd = node

#     @v.when(Statement)
#     def visit(self, node): return [node]

#     @v.when(Expression)
#     def visit(self, node):
#         if node.kind == C.E.GEN:
#             try:
#                 _assigns = self._assigns[repr(self._cur_mtd)]
#                 for e in node.es:
#                     s_e = str(e)
#                     for _exp in _assigns:
#                         if s_e in _exp:
#                             logging.debug("{} => {}".format(str(node), s_e))
#                             return e
#             except KeyError:
#                 logging.debug("no expressions for {}".format(self._cur_mtd))

#         return node


# """
# Replacing method generators
# """


# class MGReplacer(object):

#     def __init__(self, output_path):
#         self._output = output_path

#         # assignment appearances
#         self._assigns = {}  # { mtd : exp* }

#         # interpret the synthesis result
#         with open(self._output, 'r') as f:
#             for line in f:
#                 line = line.strip()
#                 try:
#                     items = line.split(',')
#                     func, kind, msg = items[0], items[1], ','.join(items[2:])
#                     if kind in ["StmtAssign", "StmtVarDecl"]:
#                         util.mk_or_append(self._assigns, func, msg)
#                 except IndexError:  # not a line generated by custom codegen
#                     pass  # if "Total time" in line: logging.info(line)

#     @v.on("node")
#     def visit(self, node):
#         """
#         This is the generic method to initialize the dynamic dispatcher
#         """

#     @v.when(Program)
#     def visit(self, node): pass

#     @v.when(Clazz)
#     def visit(self, node): pass

#     @v.when(Field)
#     def visit(self, node): pass

#     @v.when(Method)
#     def visit(self, node):
#         if not hasattr(node, "generator"):
#             return
#         logging.debug("retrieving {}.{}".format(node.clazz.name, node.name))
#         # reset the body, which was previously delegated to the generator
#         node.body = []

#         # retrieve assignments from Sketch output
#         mname = repr(node)
#         if mname in self._assigns:
#             # prologue: define return variable: _out
#             rty = node.typ if node.typ != C.J.v else C.J.OBJ
#             node.body = to_statements(node, u"{} _out;".format(rty))

#             op_strip = op.methodcaller("strip")
#             _assigns = self._assigns[mname]
#             for _assign in _assigns:
#                 lhs, rhs = map(op_strip, _assign.split('='))
#                 if len(lhs.split(' ')) > 1:  # i.e., var decl
#                     ty, v = map(op_strip, lhs.split(' '))
#                     # TODO: cleaner way to retrieve/sanitize type
#                     ty = ty.split('@')[0]
#                     node.body += to_statements(node,
#                                                u"{} {} = {};".format(ty, v, rhs))
#                 else:  # stmt assign
#                     node.body += to_statements(node, u"{};".format(_assign))

#             # epilogue: return _out if necessary
#             if node.typ != C.J.v:
#                 node.body += to_statements(node, u"return _out;")

#     @v.when(Statement)
#     def visit(self, node): return [node]

#     @v.when(Expression)
#     def visit(self, node): return node
