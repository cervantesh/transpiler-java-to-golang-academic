CXX ?= g++
CXXFLAGS ?= -std=c++17 -Isrc -Ibuild
BISON ?= bison
FLEX ?= flex

BUILD_DIR := build
TARGET := $(BUILD_DIR)/javago

.PHONY: all clean test

all: $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/parser.cpp $(BUILD_DIR)/parser.hpp: src/parser.y | $(BUILD_DIR)
	$(BISON) -d -o $(BUILD_DIR)/parser.cpp src/parser.y

$(BUILD_DIR)/lexer.cpp: src/lexer.l $(BUILD_DIR)/parser.hpp | $(BUILD_DIR)
	$(FLEX) -o $(BUILD_DIR)/lexer.cpp src/lexer.l

$(TARGET): $(BUILD_DIR)/parser.cpp $(BUILD_DIR)/lexer.cpp src/ast.cpp src/diagnostics.cpp src/generator.cpp src/main.cpp
	$(CXX) $(CXXFLAGS) $(BUILD_DIR)/parser.cpp $(BUILD_DIR)/lexer.cpp src/ast.cpp src/diagnostics.cpp src/generator.cpp src/main.cpp -o $(TARGET)

test: all
	pwsh ./test.ps1

clean:
	rm -rf $(BUILD_DIR) tests/generated
