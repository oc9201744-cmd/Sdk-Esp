include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Blackshark

ARCHS = arm64
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

# Gerekli Frameworkler ve Substrate
Blackshark_FRAMEWORKS = IOKit UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController Metal MetalKit
Blackshark_LIBRARIES = substrate

Blackshark_CFLAGS = -fno-lto -fobjc-arc -Wno-deprecated-declarations -fvisibility=hidden -fpermissive -fexceptions -w \
                   -I. -I./SDK -I./ESP -I./KittyMemory -I./SDK/SDK
                   
Blackshark_CCFLAGS = -fno-lto -std=c++17 -fno-rtti -fno-exceptions -DNDEBUG -fvisibility=hidden -fpermissive -fexceptions -w \
                    -I. -I./SDK -I./ESP -I./KittyMemory -I./SDK/SDK

Blackshark_LDFLAGS = -lc++ -Wl,-undefined,dynamic_lookup

# Dosya Bulucular
ESP_FILES = $(shell find ESP -name "*.mm" -o -name "*.cpp")
SDK_FILES = $(shell find SDK -name "*.cpp" -o -name "*.mm")
KITTY_FILES = $(shell find KittyMemory -name "*.cpp" -o -name "*.mm")
IMGUI_FILES = $(shell find ESP/imgui -name "*.cpp" -o -name "*.mm")

# Onur.mm dosyasını manuel olarak sona ekliyoruz
Blackshark_FILES = $(ESP_FILES) $(SDK_FILES) $(KITTY_FILES) $(IMGUI_FILES) ESP/Onur.mm

include $(THEOS_MAKE_PATH)/tweak.mk
