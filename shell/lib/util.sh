#!/bin/bash

COMMAND_EXECUTOR="#!/bin/bash
    LAST_LINE=\$(tail -n 1 '$HISTORY_FILE')

    if [ \"\$LAST_LINE\" != '' ] && [ \"\$LAST_LINE\" != '$BLOCK_SEPARATOR_FILE' ]; then
        echo '$BLOCK_SEPARATOR_FILE' >> $HISTORY_FILE
    fi

    echo \"$TERM_SYMBOL %s\" >> $HISTORY_FILE

    %s  >> $HISTORY_FILE 2>> $HISTORY_FILE || echo 'Command execution failed' >> $HISTORY_FILE
"

wait_for_press() {
    read -n 1 -s -r -p "Press any key to continue ..."
}

cut_str() {
    local str="$1"
    local max_length="$2"
    if [ ${#str} -gt $max_length ]; then
        echo "${str:0:$max_length}..."
    else
        echo "$str"
    fi
}

# Признаки колонок
# - колонки не содержат пробелов, и разделены произвольным числом пробелов и табуляций
# - последняя колонка может содержать пробелы
# - число колонок может быть задано - или произвольным
# - Колонки могут быть выровнены по одному из краев (могут быть и по левому и по правому)
# - Кроме колонок перед таблицей и после нее может быть некий текст, его нужно игнорировать
# - Первая строка может быть заголовком либо данными
parse_grid_output_to_array() {
    input="$1"
    while IFS= read -r line; do
        IFS=$' \t' read -a array <<< "$line"
        # Делайте что-то с массивом...
        # Например, распечатайте все элементы массива
        for element in "${array[@]}"; do
            echo "$element"
        done
    done <<< "$input"
}
