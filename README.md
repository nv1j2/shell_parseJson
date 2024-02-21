纯shell版json解析器。
分别进行JSON词法分析
######词法分析########
# //匹配数字
# NUMBER
#     : '-'? INT '.' [0-9]+ EXP?  // 1.35  ,1.35E-9 , 0.3 ,-4.5
#     | '-'? INT EXP            //1e10 -3e4
#     | '-'? INT                //-3 -35
#     ;
# fragment INT : '0' | [1-9][0-9]* ;
# fragment EXP : [Ee] [+\-]? INT ;
#NFA->DFA状态转换表
#	-	0	1-9	0-9	Ee	.	+-	EOF
#1	2	3	4
#2		3	4
#3					6	5		10
#4				4	6	5		10
#5				8
#6		10	9				7
#7		10	9
#8					6			10
#9				9				10
#10正常结束
#11错误结束

#######语法分析#######
#构造语法分析树,LL(1),递归向下法,自顶向下分析
#json
#    : object
#    | array
#    ;
#object
#    : '{' pair (',' pair)* '}'
#    | '{' '}' //空对象的情况
#    ;
#pair : STRING ':' value ;
#
#array
#    : '[' value (',' value)* ']'
#    | '[' ']'  //空数组的情况
#    ;
#value
#    : STRING
#    | NUMBER
#    | object    //递归
#    | array     //递归
#    | BOOLVALUE
#    | NULL
#    ;
#

最终解析json数据
