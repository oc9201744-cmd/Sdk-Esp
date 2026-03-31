include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Blackshark

ARCHS = arm64
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

Blackshark_FRAMEWORKS = IOKit UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController Metal MetalKit

# KittyMemory hatalarını önlemek için -D KITTYMEMORY_DEBUG ve diğerlerini ekledik
Blackshark_CFLAGS = -fno-lto -fobjc-arc -Wno-deprecated-declarations -fvisibility=hidden -fpermissive -fexceptions -w \
                   -I. -I./SDK -I./ESP -I./KittyMemory \
                   -D KITTYMEMORY_DEBUG
                   
Blackshark_CCFLAGS = -fno-lto -std=c++17 -fno-rtti -fno-exceptions -DNDEBUG -fvisibility=hidden -fpermissive -fexceptions -w \
                    -I. -I./SDK -I./ESP -I./KittyMemory \
                    -D KITTYMEMORY_DEBUG

Blackshark_LDFLAGS = -lc++ -Wl,-undefined,dynamic_lookup
Blackshark_USE_SUBSTRATE = 0

# Dosya Bulucular
ESP_FILES = $(shell find ESP -name "*.mm" -o -name "*.cpp")
SDK_FILES = $(shell find SDK -name "*.cpp" -o -name "*.mm")
KITTY_FILES = $(shell find KittyMemory -name "*.cpp" -o -name "*.mm")
IMGUI_FILES = $(shell find ESP/imgui -name "*.cpp" -o -name "*.mm")

Blackshark_FILES = $(ESP_FILES) $(SDK_FILES) $(KITTY_FILES) $(IMGUI_FILES)

include $(THEOS_MAKE_PATH)/tweak.mk
