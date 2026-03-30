# THEOS yolunu boş bırakıyoruz, .yml dosyası bunu otomatik dolduracak
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Blackshark

# Mimari ayarları
ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

# Framework ve Linker Ayarları
Blackshark_FRAMEWORKS = IOKit UIKit Foundation Security QuartzCore CoreGraphics CoreText AVFoundation Accelerate GLKit SystemConfiguration GameController
# Eğer JRMemory kullanmıyorsan bu satırı silebilirsin
Blackshark_EXTRA_FRAMEWORKS = JRMemory

# Path Ayarları - Klasör yapına (ESP ve SDK) göre güncellendi
Blackshark_CFLAGS = -fno-lto -fobjc-arc -Wno-deprecated-declarations -fvisibility=hidden -fpermissive -fexceptions -w -I. -I./SDK -F$(THEOS_PROJECT_DIR)
Blackshark_CCFLAGS = -fno-lto -std=c++17 -fno-rtti -fno-exceptions -DNDEBUG -fvisibility=hidden -fpermissive -fexceptions -w -I. -I./SDK -F$(THEOS_PROJECT_DIR)

# LDFLAGS
Blackshark_LDFLAGS = -lc++ -F$(THEOS_PROJECT_DIR)
Blackshark_USE_SUBSTRATE = 0

# Dosya Listesi - Ekran görüntündeki ESP ve SDK klasörlerine göre ayarlandı
Blackshark_FILES = $(wildcard ESP/*.mm) \
                   $(wildcard ESP/*.cpp) \
                   $(wildcard SDK/*.cpp) \
                   $(wildcard ESP/View/*.m) \
                   $(wildcard ESP/Module/*.mm) \
                   $(wildcard ESP/utils/*.mm) \
                   $(wildcard ESP/utils/*.cpp) \
                   $(wildcard ESP/View/*.mm) \
                   $(wildcard ESP/imgui/*.cpp) \
                   $(wildcard ESP/imgui/*.mm)

include $(THEOS_MAKE_PATH)/tweak.mk
