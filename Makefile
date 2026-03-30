# THEOS yolunu sildik, .yml üzerinden gelecek
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Blackshark

# Mimari ve Paket Ayarları
ARCHS = arm64
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

# Frameworkler - JRMemory'yi buradan sildik
Blackshark_FRAMEWORKS = IOKit UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController Metal MetalKit

# Path Ayarları - ESP ve SDK klasörlerine odaklanıyoruz
Blackshark_CFLAGS = -fno-lto -fobjc-arc -Wno-deprecated-declarations -fvisibility=hidden -fpermissive -fexceptions -w -I. -I./SDK -F.
Blackshark_CCFLAGS = -fno-lto -std=c++17 -fno-rtti -fno-exceptions -DNDEBUG -fvisibility=hidden -fpermissive -fexceptions -w -I. -I./SDK -F.

# Linker Ayarları
Blackshark_LDFLAGS = -lc++ -Wl,-undefined,dynamic_lookup
Blackshark_USE_SUBSTRATE = 0

# Dosya Listesi - ESP ve SDK içindeki her şeyi derle
Blackshark_FILES = $(wildcard ESP/*.mm) \
                   $(wildcard ESP/*.cpp) \
                   $(wildcard SDK/*.cpp) \
                   $(wildcard ESP/imgui/*.cpp) \
                   $(wildcard ESP/imgui/*.mm)

include $(THEOS_MAKE_PATH)/tweak.mk
