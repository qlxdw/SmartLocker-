# 编译器设置
CC = gcc
CFLAGS = -Wall -Wextra -g -I.
LDFLAGS = -lsqlite3

# 目标文件
TARGET = myapp
SRCS = main.c server.c
OBJS = $(SRCS:.c=.o)

# 默认目标
all: $(TARGET)

# 生成可执行文件
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# 生成目标文件
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# 清理
clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all clean