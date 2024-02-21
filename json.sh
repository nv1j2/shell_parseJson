#!/bin/sh
#bourne shell版JSON解析器, 1.0


#构建数组
#将数值放入数组中,第一个参数传入数组名称,第二个参数传入下标,第三个参数传入数组值
setArray(){
    local arrayName=$1;
    local index=$2;
    local value=$3;
    #获取数组长度
    local length=$(getArrayLength $arrayName);
    if (( 0 == $length ));then
        export ${arrayName}_Length="1";
        export ${arrayName}_${index}="${value}";
        return;
    elif (( ${length} <= ${index} ));then
        length=$index;
        let "length+=1";
        export ${arrayName}_Length="${length}";
    fi
    export ${arrayName}_${index}="${value}";
}
#将数组认为是一个栈,向数组的最后一个节点新增,第一个参数传入数组名称,第二个参数传入数组值
pushArray(){
    local arrayName=$1;
    local value=$2;
    #获取数组长度
    local length=$(getArrayLength $arrayName);
    setArray $arrayName $length $value
}


#获得数组的值,第一个参数传入数组名称,第二个参数传入下标
getArray(){
    local arrayName=$1;
    local index=$2;
    echo $(eval echo '$'${arrayName}_${index});
}
#获得数组长度,第一个参数传入数组名称
getArrayLength(){
    local arrayName=$1;
    local value=$(eval echo '$'${arrayName}_Length);
    if [ ! -n "$value" ];then
        echo 0
    else
        echo $value
    fi

}
#按照下标移除数组,第一个参数传入数组名称,第二个参数传入下标,如果下标是0,则移除整个数组
removeArray(){
    local arrayName=$1;
    local index=$2;
    local length=$(getArrayLength $arrayName);
    if (( ${index}<${length} ));then
        if(( 0 == $index));then
            unset ${arrayName}_Length;
        else
            local count=$index;
            let "length+=1";
            export ${arrayName}_Length="${count}";
        fi
    fi
    while((${index}<${length}));do
        unset ${arrayName}_${index};
        let "index+=1";
    done;
}

#数组模块使用示例
#setArray "ArrayName" 0 "name0;echo 0"
#setArray "ArrayName" 1 "name1;echo 1"
#setArray "ArrayName" 2 "name2;echo 2"
#setArray "ArrayName" 3 "name3;echo 3"
#a0=$(getArray "ArrayName" 0)
#a1=$(getArray "ArrayName" 1)
#a2=$(getArray "ArrayName" 2)
#a3=$(getArray "ArrayName" 3)
#echo "a0:"$a0
#echo "a1:"$a1
#echo "a2:"$a2
#echo "a3:"$a3
#removeArray "ArrayName" 2
#echo $(getArrayLength "ArrayName")
#a0=$(getArray "ArrayName" 0)
#a1=$(getArray "ArrayName" 1)
#a2=$(getArray "ArrayName" 2)
#a3=$(getArray "ArrayName" 3)
#echo "a0:"$a0
#echo "a1:"$a1
#echo "a2:"$a2
#echo "a3:"$a3


###############################################
####构建map模块################################
###############################################
#put map的value值,向map中放入元素,第一个参数为map名称,第二个参数map的key名,第三个参数map的value值
putMap(){
    local name=$1;
    local key=$2;
    local value=$3;
    local arrayKeyName=${name}_key;
    local arrayValueName=${name}_value;
    local length=$(getArrayLength ${arrayKeyName});
    local count=0;
    while(( ${count} < ${length} ));do
        local keyEnt=$(getArray ${arrayKeyName} ${count});
        if [[ "$keyEnt" == "$key" ]];then
            setArray ${arrayValueName} ${count} ${value};
            return;
        fi
        let "count+=1";
    done
    setArray ${arrayKeyName} ${length} ${key};
    setArray ${arrayValueName} ${length} ${value};
}
#get map的value值,向map中取出元素,第一个参数为map名称,第二个参数map的key名
getMap(){
    local name=$1;
    local key=$2;
    local arrayKeyName=${name}_key;
    local arrayValueName=${name}_value;
    local length=$(getArrayLength ${arrayKeyName});
    local count=0;
     while(( ${count} < ${length} ));do
        local keyEnt=$(getArray ${arrayKeyName} ${count});
        if [[ "$keyEnt" == "$key" ]];then
            echo $(getArray ${arrayValueName} ${count})
            return;
        fi
        let "count+=1";
    done
}
#清空map,第一个参数为map名称
cleanMap(){
    local name=$1;
    local arrayKeyName=${name}_key;
    local arrayValueName=${name}_value;
    removeArray ${arrayKeyName} 0
    removeArray ${arrayValueName} 0
}

#map模块使用示例
#putMap "map1" "map1Key" "map1Value";
#map1Key=$(getMap "map1" "map1Key");
#echo "map1Key:"$map1Key;
#putMap "map1" "map1Key" "map1Value1";
#map1Key=$(getMap "map1" "map1Key");
#echo "map1Key:"$map1Key;
#putMap "map1" "map2Key" "map1Value2";
#map2Key=$(getMap "map1" "map2Key");
#echo "map2Key:"$map2Key;
#putMap "map2" "map2Key" "map2Value1";
#map2Key=$(getMap "map2" "map2Key");
#echo "map2Key:"$map2Key;
#cleanMap "map1";
#map2Key=$(getMap "map1" "map2Key");
#echo "map1Key:"$map2Key;



############################
#####JSON词法分析###########
############################
#JSON词法分析器,第一个参数传入json名,第二个参数传入需要解析的JSON字符串
parseJson(){
    # WS  : [ \t\n\r]+ -> skip ;
    #将jsonString从字符串拆成数组
    local jsonName=$1
    local jsonString=$2;
    local index=${#jsonString};
    local i=1;
    while (( i<=index ));do
        local char=${jsonString:$i-1:1};
        #忽略空格\t\n\r
        #WS  : [ \t\n\r]+ -> skip ;
        if [[ $char == " " ]] || [[ $char == $'\t' ]] || [[ $char == $'\n' ]] || [[ $char == $'\r' ]];then
            let "i+=1";
            continue;
        fi
        #匹配String
        # STRING : '"' (ESC | ~["\\])* '"' ; //除了双引号和斜杠
        #
        # //ESC规则匹配一个unicode序列或预定义的转义字符
        # fragment ESC : '\\'(["\\/bfnrt] | UNICODE ) ;
        # fragment UNICODE : 'u' HEX HEX HEX HEX ;
        # fragment HEX : [0-9a-fA-F] ;
        if [[ $char == $'"' ]] || [[ $char == $"'" ]];then
             #进入string解析,由于我们只取值,不进行严格校验,对于ESC的匹配规则可进行部分忽略,为出现"并且"前只有偶数个\(包括0个)
             local stringValue="";
             let "i+=1";
             local char=${jsonString:$i-1:1};#待17环境兼容
             while [[ $char != $'"' ]] && [[ $char != $"'" ]]
             do
                 local stringValue=${stringValue}${char};
                 if [[ $char == "\\" ]];then
                     let "i+=1";
                     local char=${jsonString:$i-1:1};
                     local stringValue=${stringValue}${char};
                 fi
                 let "i+=1";
                 local char=${jsonString:$i-1:1};
                 if (( i > index ));then
                     echo "解析json异常,预期是\"结尾,但未找到\"";
                     return 1;
                 fi
             done
             #if $stringValue == (\\( ["\\/bfnrt] | u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])|~["\\])*
             pushArray "JsonParseTokens" "String";
             pushArray "JsonParseTokenValues" "${stringValue}";
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
        elif  [[ $char == $"-" ]] || [[ $char == $"0" ]] || [[ $char == $"1" ]] || [[ $char == $"2" ]] || [[ $char == $"3" ]] || [[ $char == $"4" ]] || [[ $char == $"5" ]] || [[ $char == $"6" ]] || [[ $char == $"7" ]] || [[ $char == $"8" ]] || [[ $char == $"9" ]];then
            local stringValue=$char;
            local state=11;
            if [[ $char == $"-" ]];then
                local state=2;
            elif [[ $char == $"0" ]];then
                local state=3;
            else
                local state=4;
            fi
            while true
            do
                let "i+=1";
                if(( i > index ));then
                    local state=10;
                else
                    local char=${jsonString:$i-1:1};
                fi
                if (( $state == 2 ));then
                    if [[ $char == $"0" ]];then
                        local state=3;
                    elif [[ $char == $"1" ]] || [[ $char == $"2" ]] || [[ $char == $"3" ]] || [[ $char == $"4" ]] || [[ $char == $"5" ]] || [[ $char == $"6" ]] || [[ $char == $"7" ]] || [[ $char == $"8" ]] || [[ $char == $"9" ]];then
                        local state=4;
                    else
                        local state=11;
                    fi
                elif (( $state == 3 ));then
                    if [[ $char == $"E" ]] || [[ $char == $"e" ]];then
                        local state=6;
                    elif [[ $char == $"." ]];then
                        local state=5;
                    else
                        local state=10;
                    fi
                elif (( $state == 4 ));then
                    if [[ $char == $"0" ]] || [[ $char == $"1" ]] || [[ $char == $"2" ]] || [[ $char == $"3" ]] || [[ $char == $"4" ]] || [[ $char == $"5" ]] || [[ $char == $"6" ]] || [[ $char == $"7" ]] || [[ $char == $"8" ]] || [[ $char == $"9" ]];then
                        local state=4;
                    elif [[ $char == $"E" ]] || [[ $char == $"e" ]];then
                        local state=6;
                    elif [[ $char == $"." ]];then
                        local state=5;
                    else
                        local state=10;
                    fi
                elif (( $state == 5 ));then
                    if [[ $char == $"0" ]] || [[ $char == $"1" ]] || [[ $char == $"2" ]] || [[ $char == $"3" ]] || [[ $char == $"4" ]] || [[ $char == $"5" ]] || [[ $char == $"6" ]] || [[ $char == $"7" ]] || [[ $char == $"8" ]] || [[ $char == $"9" ]];then
                        local state=8;
                    else
                        local state=11;
                    fi
                elif (( $state == 6 ));then
                    if [[ $char == $"0" ]];then
                        local state=10;
                    elif [[ $char == $"1" ]] || [[ $char == $"2" ]] || [[ $char == $"3" ]] || [[ $char == $"4" ]] || [[ $char == $"5" ]] || [[ $char == $"6" ]] || [[ $char == $"7" ]] || [[ $char == $"8" ]] || [[ $char == $"9" ]];then
                        local state=9;
                    elif [[ $char == $"+" ]] || [[ $char == $"-" ]];then
                        local state=7;
                    else
                       local state=11;
                    fi
                elif (( $state == 7 ));then
                    if [[ $char == $"0" ]];then
                        local state=10;
                    elif [[ $char == $"1" ]] || [[ $char == $"2" ]] || [[ $char == $"3" ]] || [[ $char == $"4" ]] || [[ $char == $"5" ]] || [[ $char == $"6" ]] || [[ $char == $"7" ]] || [[ $char == $"8" ]] || [[ $char == $"9" ]];then
                        local state=9;
                    else
                        local state=11;
                    fi
                elif (( $state == 8 ));then
                    if [[ $char == $"E" ]] || [[ $char == $"e" ]];then
                        local state=6;
                    else
                        local state=10;
                    fi
                elif (( $state == 9 ));then
                    if [[ $char == $"0" ]] || [[ $char == $"1" ]] || [[ $char == $"2" ]] || [[ $char == $"3" ]] || [[ $char == $"4" ]] || [[ $char == $"5" ]] || [[ $char == $"6" ]] || [[ $char == $"7" ]] || [[ $char == $"8" ]] || [[ $char == $"9" ]];then
                        local state=9;
                    else
                        local state=10;
                    fi
                fi
                if (( $state < 10 ));then
                    local stringValue=${stringValue}${char};
                elif (( $state == 10 ));then
                    let "i-=1";
                    pushArray "JsonParseTokens" "Number";
                    pushArray "JsonParseTokenValues" "${stringValue}";
                    break;
                else
                    echo ${state},${char},${stringValue};
                    echo "数字分词解析器读取字符与预期字符不一致.";
                    return 1 ;
                fi
            done
        # BOOLVALUE
        #     : 'false'
        #     | 'true'
        #     ;
        elif [[ $char == $"t" ]] || [[ $char == $"T" ]] ;then
            local stringValue=$char;
            let "i+=1";
            local char=${jsonString:$i-1:1};
            if [[ $char == $"r" ]] || [[ $char == $"R" ]] ;then
                local stringValue=${stringValue}${char};
                let "i+=1";
                local char=${jsonString:$i-1:1};
                if [[ $char == $"u" ]] || [[ $char == $"U" ]] ;then
                    local stringValue=${stringValue}${char}
                    let "i+=1";
                    local char=${jsonString:$i-1:1};
                    if [[ $char == $"e" ]] || [[ $char == $"E" ]] ;then
                        local stringValue=${stringValue}${char};
                        pushArray "JsonParseTokens" "Boolean"
                        pushArray "JsonParseTokenValues" "${stringValue}"
                        break;
                    fi
                fi
            fi
            echo "Bool值分词异常."
            return 1 ;
        elif [[ $char == $"f" ]] || [[ $char == $"F" ]] ;then
            local stringValue=$char;
            let "i+=1";
            local char=${jsonString:$i-1:1};
            if [[ $char == $"a" ]] || [[ $char == $"A" ]] ;then
                local stringValue=${stringValue}${char};
                let "i+=1";
                local char=${jsonString:$i-1:1};
                if [[ $char == $"l" ]] || [[ $char == $"L" ]] ;then
                    local stringValue=${stringValue}${char};
                    let "i+=1";
                    local char=${jsonString:$i-1:1};
                    if [[ $char == $"s" ]] || [[ $char == $"S" ]] ;then
                        local stringValue=${stringValue}${char};
                        let "i+=1";
                        local char=${jsonString:$i-1:1};
                        if [[ $char == $"e" ]] || [[ $char == $"E" ]] ;then
                            local stringValue=${stringValue}${char};
                            pushArray "JsonParseTokens" "Boolean"
                            pushArray "JsonParseTokenValues" "${stringValue}"
                            break;
                        fi
                    fi
                fi
            fi
            echo "Bool值分词异常."
            return 1 ;
        #NULL : 'null' ;
        elif [[ $char == $"n" ]] || [[ $char == $"N" ]] ;then
            local stringValue=$char;
            let "i+=1";
            local char=${jsonString:$i-1:1};
            if [[ $char == $"u" ]] || [[ $char == $"U" ]] ;then
                local stringValue=${stringValue}${char};
                let "i+=1";
                local char=${jsonString:$i-1:1};
                if [[ $char == $"l" ]] || [[ $char == $"L" ]] ;then
                    local stringValue=${stringValue}${char};
                    let "i+=1";
                    local char=${jsonString:$i-1:1};
                    if [[ $char == $"l" ]] || [[ $char == $"L" ]] ;then
                        local stringValue=${stringValue}${char};
                        pushArray "JsonParseTokens" "Null"
                        pushArray "JsonParseTokenValues" "${stringValue}"
                        break;
                    fi
                fi
            fi
            echo "null值分词异常."
            return 1 ;
        elif [[ $char == $"{" ]] ;then
            pushArray "JsonParseTokens" "{"
            pushArray "JsonParseTokenValues" "{"
        elif [[ $char == $"}" ]] ;then
            pushArray "JsonParseTokens" "}"
            pushArray "JsonParseTokenValues" "}"
        elif [[ $char == $"[" ]] ;then
            pushArray "JsonParseTokens" "["
            pushArray "JsonParseTokenValues" "["
        elif [[ $char == $"]" ]] ;then
            pushArray "JsonParseTokens" "]"
            pushArray "JsonParseTokenValues" "]"
        elif [[ $char == $"," ]] ;then
            pushArray "JsonParseTokens" ","
            pushArray "JsonParseTokenValues" ","
        elif [[ $char == $":" ]] ;then
            pushArray "JsonParseTokens" ":"
            pushArray "JsonParseTokenValues" ":"
        else
            echo "词法分析器读取字符 "${char}" 不是预期的字符,请检查json格式是否正确";
            return 1;
        fi

        let "i+=1"
    done
    #语法分析器,并且将值编译放进目标数组
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

    #获取下一个token值
    nextJsonToken(){
         let "json_grammer_index+=1";
         token=$(getArray "JsonParseTokens" $json_grammer_index);
    }
    #设置语法解析异常标志
    setError(){
         json_grammer_index=-1
    }

    #解析value值
    #value
    #    : STRING
    #    | NUMBER
    #    | object    //递归
    #    | array     //递归
    #    | BOOLVALUE
    #    | NULL
    #    ;
    #第一个参数传入jsonName值,第二个参数传入name值
    parseJsonValue(){
        local jsonName=$1;
        local name=$2;
        #echo ${json_grammer_index}":"${token}
        if [[ ${token} == "String" ]] || [[ ${token} == "Number" ]] || [[ ${token} == "Boolean" ]] || [[ ${token} == "Null" ]] || [[ ${token} == "{" ]] || [[ ${token} == "[" ]];then
            if [[ ${token} == "{" ]];then
                parseJsonObject ${jsonName} ${name}
            elif [[ ${token} == "[" ]];then
                parseJsonArray ${jsonName} ${name}
            else
                local value=$(getArray "JsonParseTokenValues" $json_grammer_index);
                #echo "value1:"${jsonName}","${name}","${value}
                putMap ${jsonName} ${name} ${value};
            fi
        else
            setError
        fi
    }

    ##pair : STRING ':' value ;
    #json解析循环pair
    #第一个参数传入name
    parseJsonPair(){
        local jsonName=$1;
        local name=$2;
        #echo ${json_grammer_index}":"${token}
        if [[ ${token} == "String" ]];then
            local name=${name}.$(getArray "JsonParseTokenValues" $json_grammer_index)
            nextJsonToken
            #echo ${json_grammer_index}":"${token}
            if [[ ${token} == ":" ]];then
                nextJsonToken
                #echo ${json_grammer_index}":"${token}
                parseJsonValue ${jsonName} ${name}
                return
            fi
        fi
        setError

    }
    #编译:当到解析到非递归value值时,将value值和对应的key放到目标数组putMap中
    #第一个参数传入当前名称栈值,第二个参数传入json的名称
    #object
    #    : '{' pair (',' pair)* '}'
    #    | '{' '}' //空对象的情况
    parseJsonObject(){
        local jsonName=$1;
        local name=$2;
        #echo ${json_grammer_index}":"${token}
        if [[ ${token} == "{" ]];then
            nextJsonToken
            #echo ${json_grammer_index}":"${token}
            if [[ ${token} == "}" ]] ;then
                return;
            else
                parseJsonPair ${jsonName} ${name}
                if (( $json_grammer_index == -1 ));then
                    return;
                fi
                nextJsonToken
                #echo ${json_grammer_index}":"${token}
                while [[ ${token} == "," ]];do
                    nextJsonToken
                    parseJsonPair ${jsonName} ${name}
                    if (( $json_grammer_index == -1 ));then
                        return;
                    fi
                    nextJsonToken
                    #echo ${json_grammer_index}":"${token}
                done
                if [[ ${token} == "}" ]] ;then
                    return;
                fi
            fi
        fi
        setError
    }

    #array
    #    : '[' value (',' value)* ']'
    #    | '[' ']'  //空数组的情况
    #第一个参数传入当前名称栈值,第二个参数传入json的名称
    parseJsonArray(){
        local jsonName=$1;
        local name=$2;
        if [[ ${token} == "[" ]];then
            nextJsonToken
            #echo ${json_grammer_index}":"${token}
            if [[ ${token} == "]" ]] ;then
                return;
            else
                local parseJsonArrayCount=0;
                parseJsonValue ${jsonName} ${name}.${parseJsonArrayCount}
                if (( $json_grammer_index == -1 ));then
                    return;
                fi
                nextJsonToken
                #echo ${json_grammer_index}":"${token}
                while [[ ${token} == "," ]];do
                    nextJsonToken
                    #echo ${json_grammer_index}":"${token}
                    let "parseJsonArrayCount+=1";
                    parseJsonValue ${jsonName} ${name}.${parseJsonArrayCount}
                    if (( $json_grammer_index == -1 ));then
                        return;
                    fi
                    nextJsonToken
                    #echo ${json_grammer_index}":"${token}
                done
                let "parseJsonArrayCount+=1";
                putMap ${jsonName} ${name}.length ${parseJsonArrayCount}
                if [[ ${token} == "]" ]] ;then
                    return;
                fi
            fi
        fi
        setError

    }

    local count=$(getArrayLength "JsonParseTokens");
    let "count-=1";
    json_grammer_index=-1;
    token="";
    nextJsonToken
    #echo ${json_grammer_index}":"${token}
    if [[ ${token} == "{" ]] ;then
        parseJsonObject ${jsonName} ${jsonName}
    elif [[ ${token} == "[" ]];then
        parseJsonArray ${jsonName} ${jsonName}
    fi
    if (( json_grammer_index == -1 )) ;then
        echo "JSON语法分析异常,不符合JSON语法规范,请检查JSON字符串."
        return 0;
    elif (( json_grammer_index != count ));then
        echo "JSON语法分析未完成,请检查JSON字符串."
    fi

}



#main json解析入口
parseJson "json" "{\"key1\":\"va汉字lue1\",\"key2\":{\"key21\":{\"key211\":\"value21\"},\"key22\":123,\"key23\":-23E3},\"key3\":\"ajshd\",\"key4\":\"544\",\"key5\":[\"value51\",\"value52\",53],\"key6\":[{\"key61\":[\"value610\",\"value620\"]},{},{}]}"

echo $(getMap "json" "json.key1")
echo $(getMap "json" "json.key2.key21.key211")
echo $(getMap "json" "json.key2.key22")
echo $(getMap "json" "json.key2.key23")
echo $(getMap "json" "json.key3")
echo $(getMap "json" "json.key4")
echo $(getMap "json" "json.key5.length")
echo $(getMap "json" "json.key5.0")
echo $(getMap "json" "json.key5.1")
echo $(getMap "json" "json.key5.2")
echo $(getMap "json" "json.key6.length")
echo $(getMap "json" "json.key6.0.key61.1")
echo $(getMap "json" "json.key6.0.key61.2")
echo $(getMap "json" "json.key6.0.key61.length")


#输出词法分析
#length=$(getArrayLength JsonParseTokens)
#i=0
#while (( i<${length})); do
#    echo "序号:"${i}
#    echo $(getArray "JsonParseTokens" $i);
#    echo $(getArray "JsonParseTokenValues" $i);
#    let i++
#done




