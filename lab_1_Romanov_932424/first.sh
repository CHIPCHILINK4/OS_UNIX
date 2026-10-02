#!/bin/sh -e

TMPDIR_PATH=""
SOURCE_DIR=""
OUTPUT_NAME=""
  
exit_handler() {
    local rc=$?
    trap - EXIT
    if [ -n "$TMPDIR_PATH" ] && [ -d "$TMPDIR_PATH" ]; then
        rm -rf -- "$TMPDIR_PATH"
    fi
    echo "Удалено" 
    exit $rc
}
trap exit_handler EXIT HUP INT QUIT PIPE TERM
if [ -z "$1" ]; then
    echo "ERR: вы не передали файл, перезапустите и передайте первым аргументом полный путь до файла">&2
    exit 1
fi

SOURCE_FILE="$1"
 
OUTPUT_NAME=$(grep -i 'Output:' "$SOURCE_FILE" | head -n 1 | tr -d '\r' | sed  's/.*Output:[[:space:]]*//; s/[[:space:]]*$//')
BASENAME=$(basename "$SOURCE_FILE")
if [ -z "$OUTPUT_NAME" ]; then
    echo "ERR: комментарий 'Output:' не найден в '$SOURCE_FILE'." >&2
    OUTPUT_NAME="${BASENAME%.*}"
fi

echo "Целевой файл: $OUTPUT_NAME"
 
TMPDIR_PATH=$(mktemp -d)
echo "Временный каталог: $TMPDIR_PATH"

EXTENSION="${BASENAME##*.}"

case "$EXTENSION" in
    c)
        COMPILER="cc"
        IS_C=true
        ;;
    cpp|cc|cxx)
        COMPILER="c++"
        IS_C=true
        ;;
    tex)
        COMPILER="pdflatex"
        IS_C=false
        ;;
    *) 
        echo "ERR: неизвестное расширение файла." >&2
        exit 2
        ;;
esac

echo "Компилятор: $COMPILER"


cp -- "$SOURCE_FILE" "$TMPDIR_PATH/"
if [ "$IS_C" = true ]; then
    (cd "$TMPDIR_PATH" && $COMPILER -o "$OUTPUT_NAME" "$BASENAME")
else
    (cd "$TMPDIR_PATH" && $COMPILER "$BASENAME")
fi

SOURCE_DIR=$(dirname "$SOURCE_FILE")
mv -- "$TMPDIR_PATH/$OUTPUT_NAME" "$SOURCE_DIR/"

echo "Итог: '$OUTPUT_NAME' создан в '$SOURCE_DIR'."
exit 0