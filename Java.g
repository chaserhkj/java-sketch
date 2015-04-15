/** A Java 1.5 grammar for ANTLR v3 derived from the spec
 *
 *  This is a very close representation of the spec; the changes
 *  are comestic (remove left recursion) and also fixes (the spec
 *  isn't exactly perfect).  I have run this on the 1.4.2 source
 *  and some nasty looking enums from 1.5, but have not really
 *  tested for 1.5 compatibility.
 *
 *  I built this with: java -Xmx100M org.antlr.Tool java.g 
 *  and got two errors that are ok (for now):
 *  java.g:691:9: Decision can match input such as
 *    "'0'..'9'{'E', 'e'}{'+', '-'}'0'..'9'{'D', 'F', 'd', 'f'}"
 *    using multiple alternatives: 3, 4
 *  As a result, alternative(s) 4 were disabled for that input
 *  java.g:734:35: Decision can match input such as "{'$', 'A'..'Z',
 *    '_', 'a'..'z', '\u00C0'..'\u00D6', '\u00D8'..'\u00F6',
 *    '\u00F8'..'\u1FFF', '\u3040'..'\u318F', '\u3300'..'\u337F',
 *    '\u3400'..'\u3D2D', '\u4E00'..'\u9FFF', '\uF900'..'\uFAFF'}"
 *    using multiple alternatives: 1, 2
 *  As a result, alternative(s) 2 were disabled for that input
 *
 *  You can turn enum on/off as a keyword :)
 *
 *  Version 1.0 -- initial release July 5, 2006 (requires 3.0b2 or higher)
 *
 *  Primary author: Terence Parr, July 2006
 *
 *  Version 1.0.1 -- corrections by Koen Vanderkimpen & Marko van Dooren,
 *      October 25, 2006;
 *      fixed normalInterfaceDeclaration: now uses typeParameters instead
 *          of typeParameter (according to JLS, 3rd edition)
 *      fixed castExpression: no longer allows expression next to type
 *          (according to semantics in JLS, in contrast with syntax in JLS)
 *
 *  Version 1.0.2 -- Terence Parr, Nov 27, 2006
 *      java spec I built this from had some bizarre for-loop control.
 *          Looked weird and so I looked elsewhere...Yep, it's messed up.
 *          simplified.
 *
 * Jinseong Jeon, Dec 2012 -- Nov 2013
 * to support complex annotations
 *   modified the corresponding grammar
 * to generate AST, rather than a flat, 1-D list of tokens
 *   added tokens and rewriting rules
 *   indicated which tokens are root (^) or not necessary (!)
 * for richer template
 *   modified the grammars about expressions
 *
 */
grammar Java;
options {
    language=Python;
    output=AST;

    k=2;
    backtrack=true;
    memoize=true;
}

tokens {
  ANNOTATION;
  PACKAGE = 'package';
  CLASS = 'class';
  INTERFACE = 'interface';
  DECL;
  FIELD;
  METHOD;

  EXTENDS = 'extends';
  IMPLEMENTS = 'implements';
  THROWS = 'throws';

  TYPE;
  NAME;
  PARAMS;
  ELEMS;

  STAT;
  EXPR;
  ARGV;
  FOR_CTRL;
  CAST;

  HOLE = '??';
}

@lexer::init {
self.enumIsKeyword = True
}

// starting point for parsing a java file
compilationUnit
    :   annotations?
        packageDeclaration?
        importDeclaration*
        typeDeclaration*
    ;

packageDeclaration
    :   PACKAGE qualifiedName ';'
    ->  ^(PACKAGE qualifiedName)
    ;

importDeclaration
    :   'import' 'static'? Identifier ('.' Identifier)* ('.' '*')? ';'
    ;

typeDeclaration
    :   classOrInterfaceDeclaration
    |   ';'
    ;

classOrInterfaceDeclaration
    :   modifier* (classDeclaration | interfaceDeclaration)
    ;

classDeclaration
    :   normalClassDeclaration
    |   enumDeclaration
    ;

normalClassDeclaration
    :   CLASS Identifier (typeParameters)?
        (EXTENDS type)?
        (IMPLEMENTS typeList)?
        classBody
    ->  ^(CLASS
            ^(NAME Identifier (typeParameters)?)
            ^(EXTENDS type)? ^(IMPLEMENTS typeList)?
            classBody
        )
    ;

typeParameters
    :   '<' typeParameter (',' typeParameter)* '>'
    ;

typeParameter
    :   Identifier (EXTENDS bound)?
    ;

bound
    :   type ('&' type)*
    ;

enumDeclaration
    :   ENUM Identifier (IMPLEMENTS typeList)? enumBody
    ->  ^(ENUM ^(NAME Identifier) ^(IMPLEMENTS typeList)? enumBody)
    ;

enumBody
    :   '{'! enumConstants? ','? enumBodyDeclarations? '}'!
    ;

enumConstants
    :   enumConstant (',' enumConstant)*
    ;

enumConstant
    :   annotations? Identifier (arguments)? (classBody)?
    ;

enumBodyDeclarations
    :   ';' (classBodyDeclaration)*
    ;

interfaceDeclaration
    :   normalInterfaceDeclaration
    |   annotationTypeDeclaration
    ;

normalInterfaceDeclaration
    :   INTERFACE Identifier typeParameters? (EXTENDS typeList)? interfaceBody
    ->  ^(INTERFACE
            ^(NAME Identifier typeParameters?)
            ^(EXTENDS typeList)?
            interfaceBody
        )
    ;

typeList
    :   type (',' type)*
    ;

classBody
    :   '{' classBodyDeclaration* '}'
    ;

interfaceBody
    :   '{'! interfaceBodyDeclaration* '}'!
    ;

classBodyDeclaration
    :   ';'
    |   'static'? block
    |   modifier* memberDecl
    ->  ^(DECL modifier* memberDecl)
    ;

memberDecl
    :   genericMethodOrConstructorDecl
    |   methodDeclaration
    |   fieldDeclaration
    |   'void' Identifier voidMethodDeclaratorRest
    ->  ^(METHOD
            ^(TYPE 'void') ^(NAME Identifier) voidMethodDeclaratorRest
        )
    |   Identifier constructorDeclaratorRest
    ->  ^(METHOD
            ^(TYPE Identifier) ^(NAME Identifier) constructorDeclaratorRest
        )
    |   interfaceDeclaration
    |   classDeclaration
    ;

genericMethodOrConstructorDecl
    :   typeParameters genericMethodOrConstructorRest
    ;

genericMethodOrConstructorRest
    :   (type | 'void') Identifier methodDeclaratorRest
    |   Identifier constructorDeclaratorRest
    ;

methodDeclaration
    :   type Identifier methodDeclaratorRest
    ->  ^(METHOD ^(TYPE type) ^(NAME Identifier) methodDeclaratorRest)
    ;

fieldDeclaration
    :   type variableDeclarators ';'
    ->  ^(FIELD ^(TYPE type) ^(NAME variableDeclarators))
    ;

interfaceBodyDeclaration
    :   modifier* interfaceMemberDecl
    ->  ^(DECL modifier* interfaceMemberDecl)
    |   ';'
    ;

interfaceMemberDecl
    :   interfaceMethodOrFieldDecl
    |   interfaceGenericMethodDecl
    |   'void' Identifier voidInterfaceMethodDeclaratorRest
    ->  ^(METHOD
            ^(TYPE 'void') ^(NAME Identifier) voidInterfaceMethodDeclaratorRest
        )
    |   interfaceDeclaration
    |   classDeclaration
    ;

interfaceMethodOrFieldDecl
    :   type Identifier interfaceMethodDeclaratorRest
    ->  ^(METHOD
            ^(TYPE type) ^(NAME Identifier) interfaceMethodDeclaratorRest
        )
    |   type Identifier constantDeclaratorRest ';'
    ->  ^(FIELD ^(TYPE type) ^(NAME Identifier constantDeclaratorRest))
    ;

methodDeclaratorRest
    :   formalParameters ('[' ']')*
        (THROWS^ qualifiedNameList)?
        (   methodBody
        |   ';'
        )
    ;

voidMethodDeclaratorRest
    :   formalParameters (THROWS^ qualifiedNameList)?
        (   methodBody
        |   ';'
        )
    ;

interfaceMethodDeclaratorRest
    :   formalParameters ('[' ']')* (THROWS^ qualifiedNameList)? ';'
    ;

interfaceGenericMethodDecl
    :   typeParameters (type | 'void') Identifier
        interfaceMethodDeclaratorRest
    ;

voidInterfaceMethodDeclaratorRest
    :   formalParameters (THROWS^ qualifiedNameList)? ';'
    ;

constructorDeclaratorRest
    :   formalParameters (THROWS^ qualifiedNameList)?
        (   methodBody
        |   ';'
        )
    ;

constantDeclarator
    :   Identifier constantDeclaratorRest
    ;

variableDeclarators
    :   variableDeclarator (',' variableDeclarator)*
    ;

variableDeclarator
    :   Identifier variableDeclaratorRest
    ;

variableDeclaratorRest
    :   ('[' ']')+ ('='^ variableInitializer)?
    |   '='^ variableInitializer
    |
    ;

constantDeclaratorsRest
    :   constantDeclaratorRest (',' constantDeclarator)*
    ;

constantDeclaratorRest
    :   ('[' ']')* '='^ variableInitializer
    ;

variableDeclaratorId
    :   Identifier ('[' ']')*
    ;

variableInitializer
    :   arrayInitializer
    |   expression
    ;

arrayInitializer
    :   '{' (variableInitializer (',' variableInitializer)* (',')? )? '}'
    ;

modifier
    :   annotation
    |   'public'
    |   'protected'
    |   'private'
    |   'static'
    |   'abstract'
    |   'final'
    |   'native'
    |   'synchronized'
    |   'transient'
    |   'volatile'
    |   'strictfp'
    |   'generator'
    |   'harness'
    ;

packageOrTypeName
    :   Identifier ('.' Identifier)*
    ;

enumConstantName
    :   Identifier
    ;

typeName
    :   Identifier
    |   packageOrTypeName '.' Identifier
    ;

type
    :   Identifier (typeArguments)? ('.' Identifier (typeArguments)? )* ('[' ']')*
    |   primitiveType ('[' ']')*
    ;

primitiveType
    :   'boolean'
    |   'char'
    |   'byte'
    |   'short'
    |   'int'
    |   'long'
    |   'float'
    |   'double'
    ;

variableModifier
    :   'final'
    |   annotation
    ;

typeArguments
    :   '<' typeArgument (',' typeArgument)* '>'
    ;

typeArgument
    :   type
    |   '?' (('extends' | 'super') type)?
    ;

qualifiedNameList
    :   qualifiedName (',' qualifiedName)*
    ;

formalParameters
    :   '(' formalParameterDecls? ')'
    ->  ^(PARAMS formalParameterDecls)?
    ;

formalParameterDecls
    :   'final'? annotations? type formalParameterDeclsRest?
    ;

formalParameterDeclsRest
    :   ('...')? variableDeclaratorId (','! formalParameterDecls)?
    ;

methodBody
    :   block
    ;

qualifiedName
    :   Identifier ('.' Identifier)*
    ;
    
literal    
    :   integerLiteral
    |   FloatingPointLiteral
    |   CharacterLiteral
    |   StringLiteral
    |   booleanLiteral
    |   'null'
    ;

integerLiteral
    :   HexLiteral
    |   OctalLiteral
    |   DecimalLiteral
    ;

booleanLiteral
    :   'true'
    |   'false'
    ;

// ANNOTATIONS

annotations
    :   annotation+
    ;

annotation
    :   '@' typeName ('(' elementList ')')?
    ->  ^(ANNOTATION ^(NAME typeName) ^(ELEMS elementList)?)
    ;

elementList
    :   elementValue
    |   elementAssign (','! elementAssign)*
    ;

elementAssign
    :   Identifier '='^ elementValue
    ;

elementValue
    :   conditionalExpression
    |   annotation
    |   elementValueArrayInitializer
    ;
    
elementValueArrayInitializer
    :   '{'! (elementValue)? (',' elementValue)* '}'!
    ;
    
annotationTypeDeclaration
    :   '@' 'interface' Identifier annotationTypeBody
    ;
    
annotationTypeBody
    :   '{' (annotationTypeElementDeclarations)? '}'
    ;
    
annotationTypeElementDeclarations
    :   (annotationTypeElementDeclaration) (annotationTypeElementDeclaration)*
    ;
    
annotationTypeElementDeclaration
    :   (modifier)* annotationTypeElementRest
    ;
    
annotationTypeElementRest
    :   type Identifier annotationMethodOrConstantRest ';'
    |   classDeclaration
    |   interfaceDeclaration
    |   enumDeclaration
    |   annotationTypeDeclaration
    ;
    
annotationMethodOrConstantRest
    :   annotationMethodRest
    |   annotationConstantRest
    ;
    
annotationMethodRest
    :  '(' ')' (defaultValue)?
    ;
     
annotationConstantRest
    :   variableDeclarators
    ;
     
defaultValue
    :   'default' elementValue
    ;

// STATS / BLOCKS

block
    :   '{' blockStatement* '}'
    ;
    
blockStatement
    :   localVariableDeclaration
    ->  ^(DECL localVariableDeclaration)
    |   classOrInterfaceDeclaration
    |   statement
    ;

localVariableDeclaration
    :   ('final')? type variableDeclarators ';'
    ;

statement
    :   block
    |   'assert' expression (':' expression)? ';'
    ->  ^(STAT 'assert' expression (':' expression)? ';')
    |   'if' parExpression statement ('else' statement)?
    ->  ^(STAT 'if' parExpression statement ('else' statement)?)
    |   'for' '(' forControl ')' statement
    ->  ^(STAT 'for' ^(FOR_CTRL forControl) statement)
    |   'while' parExpression statement
    ->  ^(STAT 'while' parExpression statement)
    |   'repeat' parExpression statement // sketch syntax
    ->  ^(STAT 'repeat' parExpression statement)
    |   'do' statement 'while' parExpression ';'
    |   'try' block catches? ('finally' block)?
    ->  ^(STAT 'try' block catches? ^('finally' block)?)
    |   'switch' parExpression '{' switchBlockStatementGroups '}'
    ->  ^(STAT 'switch' parExpression '{' switchBlockStatementGroups '}')
    |   'synchronized' parExpression block
    |   'return' expression? ';'
    ->  ^(STAT 'return' expression? ';')
    |   'throw' expression ';'
    |   'break' Identifier? ';'
    ->  ^(STAT 'break' Identifier? ';')
    |   'continue' Identifier? ';'
    |   ';'
    |   statementExpression ';'
    ->  ^(STAT statementExpression ';')
    |   Identifier ':' statement
    ;

catches
    :   catchClause (catchClause)*
    ;

catchClause
    :   'catch' '(' formalParameter ')' block
    -> ^('catch' ^(PARAMS formalParameter) block)
    ;

formalParameter
    :   variableModifier* type variableDeclaratorId
    ;

switchBlockStatementGroups
    :   (switchBlockStatementGroup)*
    ;

switchBlockStatementGroup
    :   'case' expression ':' blockStatement*
    -> ^('case' expression blockStatement*)
    |   'default' ':' blockStatement*
    -> ^('default' blockStatement*)
    ;

moreStatementExpressions
    :   (',' statementExpression)*
    ;

forControl
options {k=3;} // be efficient for common case: for (ID ID : ID) ...
    :   forVarControl
    |   forInit? ';' expression? ';' forUpdate?
    ;

forInit
    :   'final'? (annotation)? type variableDeclarators
    |   expressionList
    ;

forVarControl
    :   'final'? type Identifier ':' expression
    ;

forUpdate
    :   expressionList
    ;

// EXPRS

parExpression
    :   '('! expression ')'!
    ;

expressionList
    :   expression (','! expression)*
    ;

statementExpression
    :   expression
    ;

constantExpression
    :   expression
    ;

expression
    :   conditionalExpression (assignmentOperator expression)?
    ->  ^(EXPR conditionalExpression (assignmentOperator expression)?)
    ;

assignmentOperator
    :   '='
    |   '+='
    |   '-='
    |   '*='
    |   '/='
    |   '&='
    |   '|='
    |   '^='
    |   '%='
    |   '<' '<' '='
    |   '>' '>' '='
    |   '>' '>' '>' '='
    ;

conditionalExpression
    :   conditionalOrExpression ( '?' expression ':' expression )?
    ;

conditionalOrExpression
    :   conditionalAndExpression ( '||'^ conditionalAndExpression )*
    ;

conditionalAndExpression
    :   inclusiveOrExpression ( '&&'^ inclusiveOrExpression )*
    ;

inclusiveOrExpression
    :   exclusiveOrExpression ( '|'^ exclusiveOrExpression )*
    ;

exclusiveOrExpression
    :   andExpression ( '^'^ andExpression )*
    ;

andExpression
    :   equalityExpression ( '&'^ equalityExpression )*
    ;

equalityExpression
    :   instanceOfExpression equalityOp equalityExpression
    ->  ^(equalityOp ^(EXPR instanceOfExpression) ^(EXPR equalityExpression))
    |   instanceOfExpression
    ;

equalityOp
    :   ('==' | '!=')
    ;

instanceOfExpression
    :   relationalExpression ('instanceof' type)?
    ;

relationalExpression
    :   shiftExpression relationalOp relationalExpression
    ->  ^(relationalOp ^(EXPR shiftExpression) ^(EXPR relationalExpression))
    |   shiftExpression
    ;

relationalOp
    :   ('<=' | '>=' | '<' | '>')
    ;

shiftExpression
    :   additiveExpression ( shiftOp^ additiveExpression )*
    ;

        // TODO: need a sem pred to check column on these >>>
shiftOp
    :   ('<<' | '>>>' | '>>')
    ;

additiveExpression
    :   multiplicativeExpression additiveOp additiveExpression
    -> ^(additiveOp ^(EXPR multiplicativeExpression) ^(EXPR additiveExpression))
    |   multiplicativeExpression
    ;

additiveOp
    : ('+' | '-')
    ;

multiplicativeExpression
    :   unaryExpression ( ( '*' | '/' | '%' )^ unaryExpression )*
    ;

unaryExpression
    :   '+'^ unaryExpression
    |   '-'^ unaryExpression
    |   '++'^ primary
    |   '--'^ primary
    |   unaryExpressionNotPlusMinus
    ;

unaryExpressionNotPlusMinus
    :   '~'^ unaryExpression
    |   '!'^ unaryExpression
    |   castExpression
    |   primary selector* ('++'|'--')?
    ;

castExpression
    :   '(' primitiveType ')' unaryExpression
    ->  ^(CAST ^(TYPE primitiveType) unaryExpression)
//    |   '(' (expression | type) ')' unaryExpressionNotPlusMinus
    |   '(' expression ')' unaryExpressionNotPlusMinus
    ->  ^(CAST ^(TYPE expression) unaryExpressionNotPlusMinus)
    |   '(' type ')' unaryExpressionNotPlusMinus
    ->  ^(CAST ^(TYPE type) unaryExpressionNotPlusMinus)
    ;

primary
    :   parExpression
    |   nonWildcardTypeArguments
        (explicitGenericInvocationSuffix | 'this' arguments)
    |   'this' (arguments)?
    |   'super' superSuffix
    |   literal
    |   'new' creator
//    |   Identifier ('.' Identifier)* (identifierSuffix)?
    |   annoIdentifier ('.' annoIdentifier)* (identifierSuffix)?
    |   primitiveType ('[' ']')* '.' 'class'
    |   'void' '.' 'class'
    |   HOLE
    ;

annoIdentifier
    :   annotation
    |   Identifier
    ;

identifierSuffix
    :   ('[' ']')+ '.' 'class'
    |   ('[' expression ']')+ // can also be matched by selector, but do here
    |   arguments
    |   '.' 'class'
    |   '.' explicitGenericInvocation
    |   '.' 'this'
    |   '.' 'super' arguments
    |   '.' 'new' (nonWildcardTypeArguments)? innerCreator
    ;

creator
    :   nonWildcardTypeArguments? createdName
        (arrayCreatorRest | classCreatorRest)
    ;

createdName
    :   Identifier nonWildcardTypeArguments?
        ('.' Identifier nonWildcardTypeArguments?)*
    |   primitiveType
    ;

innerCreator
    :   Identifier classCreatorRest
    ;

arrayCreatorRest
    :   '['
        (   ']' ('[' ']')* arrayInitializer
        |   expression ']' ('[' expression ']')* ('[' ']')*
        )
    ;

classCreatorRest
    :   arguments classBody?
    ;

explicitGenericInvocation
    :   nonWildcardTypeArguments explicitGenericInvocationSuffix
    ;

nonWildcardTypeArguments
    :   '<' typeList '>'
    ;

explicitGenericInvocationSuffix
    :   'super' superSuffix
    |   Identifier arguments
    ;

selector
    :   '.' Identifier (arguments)?
    |   '.' 'this'
    |   '.' 'super' superSuffix
    |   '.' 'new' (nonWildcardTypeArguments)? innerCreator
    |   '[' expression ']'
    ;

superSuffix
    :   arguments
    |   '.' Identifier (arguments)?
    ;

arguments
    :   '(' expressionList? ')'
    ->  ^(ARGV expressionList?)
    ;

// LEXER

HexLiteral : '0' ('x'|'X') HexDigit+ IntegerTypeSuffix? ;

DecimalLiteral : ('0' | '1'..'9' '0'..'9'*) IntegerTypeSuffix? ;

OctalLiteral : '0' ('0'..'7')+ IntegerTypeSuffix? ;

fragment
HexDigit : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
IntegerTypeSuffix : ('l'|'L') ;

FloatingPointLiteral
    :   ('0'..'9')+ '.' ('0'..'9')* Exponent? FloatTypeSuffix?
    |   '.' ('0'..'9')+ Exponent? FloatTypeSuffix?
    |   ('0'..'9')+ Exponent FloatTypeSuffix?
    |   ('0'..'9')+ Exponent? FloatTypeSuffix
    ;

fragment
Exponent : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
FloatTypeSuffix : ('f'|'F'|'d'|'D') ;

CharacterLiteral
    :   '\'' ( EscapeSequence | ~('\''|'\\') ) '\''
    ;

StringLiteral
    :   '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;

fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   UnicodeEscape
    |   OctalEscape
    ;

fragment
OctalEscape
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UnicodeEscape
    :   '\\' 'u' HexDigit HexDigit HexDigit HexDigit
    ;

ENUM:   'enum' 
        {
            if not self.enumIsKeyword:
                $type = Identifier
        }
    ;

Identifier 
    :   Letter (Letter|JavaIDDigit)*
    ;

/**I found this char range in JavaCC's grammar, but Letter and Digit overlap.
   Still works, but...
 */
fragment
Letter
    :   '\u0024'
    |   '\u0041'..'\u005a'
    |   '\u005f'
    |   '\u0061'..'\u007a'
    |   '\u00c0'..'\u00d6'
    |   '\u00d8'..'\u00f6'
    |   '\u00f8'..'\u00ff'
    |   '\u0100'..'\u1fff'
    |   '\u3040'..'\u318f'
    |   '\u3300'..'\u337f'
    |   '\u3400'..'\u3d2d'
    |   '\u4e00'..'\u9fff'
    |   '\uf900'..'\ufaff'
    ;

fragment
JavaIDDigit
    :   '\u0030'..'\u0039'
    |   '\u0660'..'\u0669'
    |   '\u06f0'..'\u06f9'
    |   '\u0966'..'\u096f'
    |   '\u09e6'..'\u09ef'
    |   '\u0a66'..'\u0a6f'
    |   '\u0ae6'..'\u0aef'
    |   '\u0b66'..'\u0b6f'
    |   '\u0be7'..'\u0bef'
    |   '\u0c66'..'\u0c6f'
    |   '\u0ce6'..'\u0cef'
    |   '\u0d66'..'\u0d6f'
    |   '\u0e50'..'\u0e59'
    |   '\u0ed0'..'\u0ed9'
    |   '\u1040'..'\u1049'
    ;

WS  :   (' '|'\r'|'\t'|'\u000C'|'\n') { $channel=HIDDEN }
    ;

COMMENT
    :   '/*' ( options {greedy=false;} : . )* '*/' { $channel=HIDDEN }
    ;

LINE_COMMENT
    :   '//' ~('\n'|'\r')* '\r'? '\n' { $channel=HIDDEN }
    ;
