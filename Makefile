include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Blackshark

ARCHS = arm64
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

Blackshark_FRAMEWORKS = IOKit UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController Metal MetalKit

# .hpp dosyalarını bulabilmesi için -I (Include) yolları
Blackshark_CFLAGS = -fno-lto -fobjc-arc -Wno-deprecated-declarations -fvisibility=hidden -fpermissive -fexceptions -w -I. -I./SDK -I./SDK/include -I./ESP
Blackshark_CCFLAGS = -fno-lto -std=c++17 -fno-rtti -fno-exceptions -DNDEBUG -fvisibility=hidden -fpermissive -fexceptions -w -I. -I./SDK -I./SDK/include -I./ESP

Blackshark_LDFLAGS = -lc++ -Wl,-undefined,dynamic_lookup
Blackshark_USE_SUBSTRATE = 0

# Dosya Listesi: SDK içindeki tüm alt klasörlerdeki .cpp dosyalarını da bulur
Blackshark_FILES = $(wildcard ESP/*.mm) \
                   $(wildcard ESP/*.cpp) \
                   $(wildcard SDK/*.cpp) \
                   $(wildcard SDK/**/*.cpp) \
                   $(wildcard ESP/imgui/*.cpp) \
                   $(wildcard ESP/imgui/*.mm)

include $(THEOS_MAKE_PATH)/tweak.mk
