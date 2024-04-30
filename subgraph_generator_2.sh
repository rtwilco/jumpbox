EX_BASE_NAME="x1"
SHCD="full_sct.csv"
RACK_FILE="$(mktemp)"
LIST_FILE="$(mktemp)"
#echo RACK_FILE=$RACK_FILE
cat $SHCD |cut -d, -f4 |cut -d. -f1|grep x|sort|uniq > $RACK_FILE

echo Racks in SCT: `cat $RACK_FILE`
echo
LIST=""

cdu_to_list(){
        ANCHOR=`echo ${1:1:1}`
        if [ "x$ANCHOR" != $EX_BASE_NAME ]
        then
                echo bad EX base name $1 ignoring
                return
        fi
        #echo ANCHOR=$ANCHOR
        MULT=`echo ${1:3:1}`
        if [ -n "$MULT" ]
        then
                ROW=`echo ${1:2:1}`
                RACK1=`expr ${MULT} \* 3`
                RACK2=`expr ${MULT} \* 3 + 1`
                RACK3=`expr ${MULT} \* 3 + 2`
                if [ $RACK1 -le 9 ]
                then
                        RACK1=0$RACK1
                fi
                if [ $RACK2 -le 9 ]
                then
                        RACK2=0$RACK2
                fi
                if [ $RACK3 -le 9 ]
                then
                        RACK3=0$RACK3
                fi
                echo $EX_BASE_NAME$ROW$RACK1 >>$LIST_FILE
                echo $EX_BASE_NAME$ROW$RACK2 >>$LIST_FILE
                echo $EX_BASE_NAME$ROW$RACK3 >>$LIST_FILE
        else
                grep `echo $1|sed s/d/x/g` $RACK_FILE >>$LIST_FILE
        fi

}

for i in "$@"
do
        #CDU entries
        if echo $i |grep -E '^[d]' >/dev/null
        then
                cdu_to_list $i
                continue
        fi

        if ! grep $i $RACK_FILE >>$LIST_FILE
        then
                echo bad name $i
        fi
done

#clean list
LIST=$(cat $LIST_FILE|sort|uniq)
rm -f $LIST_FILE
for i in `echo $LIST`
do
        if grep $i $RACK_FILE >/dev/null
        then
                echo $i >>$LIST_FILE
        fi
done


LIST=$(cat $LIST_FILE)
RACKS=$(cat $RACK_FILE)
if [ -n "$LIST" ]
then
        for i in $LIST
        do
                RACKS=`echo $RACKS|sed s/$i//g`
        done
        echo
        echo RACKS to keep=$LIST
        echo
        echo RACKS TO REMOVE=$RACKS
        echo

        TMP_FILE1="$(mktemp)"
        TMP_FILE2="$(mktemp)"
        #echo TMP_FILE1 $TMP_FILE1 TMP_FILE2 $TMP_FILE2
        cat $SHCD |awk -F, '{print $1,$2,$3,$4,$5}' >$TMP_FILE1
        for i in $RACKS
        do
                cat $TMP_FILE1 |grep -v $i >$TMP_FILE2
                grep -v -e '^$' $TMP_FILE2 >$TMP_FILE1
        done
        rm -f $TMP_FILE2
        for i in `cat $TMP_FILE1|cut -d' ' -f1`
        do
                grep $i $SHCD >>$TMP_FILE2
        done


        echo your new SHCD is $TMP_FILE2
        export TMP_FILE1=$TMP_FILE2
else
        echo Invalid options
        echo example: $0 d11 d120 x10 x1104
        echo a space seperated list of sub elements desired in the shcd
        exit
fi
