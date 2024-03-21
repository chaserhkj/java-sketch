import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import javax.swing.text.html.HTMLDocument.Iterator;

import sketch.compiler.ast.core.FEReplacer;
import sketch.compiler.ast.core.FieldDecl;
import sketch.compiler.ast.core.FENode;
import sketch.compiler.ast.core.FEContext;
import sketch.compiler.ast.core.FEIdentityVisitor;
//import sketch.compiler.ast.core.Package;
import sketch.compiler.ast.core.Function;
import sketch.compiler.ast.core.Parameter;
import sketch.compiler.ast.core.Program;
import sketch.compiler.ast.core.exprs.*;
import sketch.compiler.ast.core.exprs.regens.ExprAlt;
import sketch.compiler.ast.core.exprs.regens.ExprChoiceBinary;
import sketch.compiler.ast.core.exprs.regens.ExprChoiceSelect;
import sketch.compiler.ast.core.exprs.regens.ExprChoiceUnary;
import sketch.compiler.ast.core.exprs.regens.ExprParen;
import sketch.compiler.ast.core.exprs.regens.ExprRegen;
import sketch.compiler.ast.core.stmts.*;
import sketch.compiler.ast.core.typs.StructDef;
import sketch.compiler.ast.core.typs.Type;
import sketch.compiler.ast.core.typs.TypeArray;
import sketch.compiler.ast.core.typs.TypePrimitive;
import sketch.compiler.ast.core.typs.TypeStructRef;
import sketch.compiler.ast.cuda.exprs.CudaBlockDim;
import sketch.compiler.ast.cuda.exprs.CudaInstrumentCall;
import sketch.compiler.ast.cuda.exprs.CudaThreadIdx;
import sketch.compiler.ast.cuda.exprs.ExprRange;
import sketch.compiler.ast.cuda.stmts.CudaSyncthreads;
import sketch.compiler.ast.cuda.stmts.StmtParfor;
import sketch.compiler.ast.promela.stmts.StmtFork;
import sketch.compiler.ast.promela.stmts.StmtJoin;
import sketch.compiler.ast.spmd.exprs.SpmdNProc;
import sketch.compiler.ast.spmd.exprs.SpmdPid;
import sketch.compiler.ast.spmd.stmts.SpmdBarrier;
import sketch.compiler.ast.spmd.stmts.StmtSpmdfork;
import sketch.util.annot.CodeGenerator;

import com.google.gson.Gson;
import com.google.gson.stream.JsonWriter;
import com.google.gson.stream.JsonReader;
import com.google.gson.TypeAdapter;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;
import com.google.gson.TypeAdapterFactory;
import com.google.gson.typeadapters.RuntimeTypeAdapterFactory;

@CodeGenerator
public class CSV extends FEReplacer {

  final PrintWriter out;
  RuntimeTypeAdapterFactory<FENode> nodeAdapterFactory;
  Set<Class<? extends FENode>> added_clazz = new HashSet<>();


  public CSV() {
    out = new PrintWriter(System.out);
  }

/*
  private String cur_pkg;

  @Override
  public Object visitPackage(Package spec) {
    cur_pkg = spec.getName();
    return super.visitPackage(spec);
  }
*/

  private String cur_func;

  @Override
  public Object visitProgram(Program prog) {
    prog.clazz = null;
    // Gson gson = new Gson();
    // String jsonInString = gson.toJson(prog);
    // out.println(jsonInString);

    nodeAdapterFactory
       = RuntimeTypeAdapterFactory.of(FENode.class, "class");
    
    StatsTypeAdapterFactory stats = new StatsTypeAdapterFactory();
    Gson gson = new GsonBuilder().registerTypeAdapterFactory(stats).create();
    String jsonInString = gson.toJson(prog);
    // Call gson.toJson() and fromJson methods on objects
    // System.out.println("Num JSON reads" + stats.numReads);
    // System.out.println("Num JSON writes" + stats.numWrites);


    // Set<Class<?>> modules = reflections.get(SubTypes.of(FENode.class).asClass());
    // modules.forEach(System.out::println);
    
    // nodeAdapterFactory.registerSubtype(Program.class);
    // added_clazz.add(Program.class);
    // nodeAdapterFactory.registerSubtype(Parameter.class);
    // nodeAdapterFactory.registerSubtype(Statement.class);
    // nodeAdapterFactory.registerSubtype(ExprVar.class);
    // nodeAdapterFactory.registerSubtype(ExprFunCall.class);
    // nodeAdapterFactory.registerSubtype(Function.class);
    System.out.println("------------");
    // added_clazz.forEach(System.out::println);

    // GsonBuilder builder = new GsonBuilder();
    // List<Class<? extends FENode>> added_clazzList = new ArrayList<>(added_clazz);
    // for (Class c1 : added_clazzList) {
    //   RuntimeTypeAdapterFactory<c1> rta = RuntimeTypeAdapterFactory.of(c1, "class");
    //   rta.registerSubtype(c1);
    //   builder.registerTypeAdapterFactory(rta);
    // }
    // Gson new_gson = new GsonBuilder().create();

    // RuntimeTypeAdapterFactory<Package> rta2 = RuntimeTypeAdapterFactory.of(Package.class, "class");
    // rta2.registerSubtype(Package.class, "class");
    // Gson new_gson = new GsonBuilder().registerTypeAdapterFactory(nodeAdapterFactory).create();
    // Gson new_gson = new Gson()


    // GsonBuilder builder = new GsonBuilder();
    // builder.registerTypeAdapter(FENode.class, new customTypeAdapter());
    // Gson new_gson = builder.create();

    // FENodeWrapper wrapper = new FENodeWrapper();
    // wrapper.node = prog;
    // jsonInString = new_gson.toJson(wrapper);
    // jsonInString = new_gson.toJson(prog);
    System.out.println(jsonInString);
    return super.visitProgram(prog);
  }

  @Override
  public Object visitFunction(Function func) {
    Gson gson = new Gson();
    String jsonInString = gson.toJson(func);
    // out.println(jsonInString);
    cur_func = func.getName();
    if (func.getBody().isBlock()) {
      for (Statement stmt: ((StmtBlock)func.getBody()).getStmts()){
        // printInfo(stmt);
      }
    }
    return super.visitFunction(func);
  }

  class FENodeWrapper {
    public String clazz = null;
    public FENode node = null;
  }

  class TagWrapper {
    public String clazz = null;
    public Object tag = null;
  }

  class customTypeAdapter extends TypeAdapter<FENode> {
    @Override
    public FENode read(JsonReader reader) throws IOException {
      return new ExprVar(new FEContext(), "null");
    }

    @Override
    public void write(JsonWriter jsonWriter, FENode node) throws IOException {
      if (node != null) {
        System.out.println(node.getClass().getName());
        jsonWriter.value("123");
      } else {
        jsonWriter.value("null");
      }
    }
  }

  class StatsTypeAdapterFactory implements TypeAdapterFactory {
    public int numReads = 0;
    public int numWrites = 0;
    public <T> TypeAdapter<T> create(Gson gson, TypeToken<T> type) {
      final TypeAdapter<T> delegate = gson.getDelegateAdapter(this, type);
      return new TypeAdapter<T>() {
        public void write(JsonWriter out, T value) throws IOException {
          // FENodeWrapper wrapper = new FENodeWrapper();
          if (value != null) {
            // System.out.println(value.getClass().getName());
          }
          // if (value instanceof FENodeWrapper) 

          if (value instanceof FENode) {
            if (!added_clazz.contains(value.getClass())) {
              nodeAdapterFactory.registerSubtype((Class<? extends FENode>) value.getClass());
              added_clazz.add((Class<? extends FENode>) value.getClass());
              System.out.println(((FENode) value).getOrigin());
              System.out.println(value.getClass().getName());
            }
            // TagWrapper tagWrapper = new TagWrapper();
            // tagWrapper.clazz = value.getClass().getSimpleName();
            // tagWrapper.tag = ((FENode)value).getTag();
            // if (((FENode)value).getTag() != null) {
            //   throw new IOException("tag is not null: " + ((FENode)value).getTag().toString());
            // }
            ((FENode)value).setTag(value.getClass().getSimpleName());
          }
          delegate.write(out, value);
        }
        public T read(JsonReader in) throws IOException {
          ++numReads;
          return delegate.read(in);
        }
      };
    }
  }
   


  void printInfo(Object obj) {
    String typ = obj.getClass().getSimpleName();
    FEContext ctx = ((FENode)obj).getCx();
    //out.println(cur_pkg + "," + cur_func + "," + typ + "," + obj.toString());
    out.println("\"" + cur_func + "\"," 
                + "\"" + typ + "\","
                + "\"" + ctx.getFileName() + ":" + Integer.toString(ctx.getLineNumber()) + ":" + Integer.toString(ctx.getColumnNumber()) + "\","
                + "\"" + obj.toString() + "\"");
    out.flush();
  }
}
