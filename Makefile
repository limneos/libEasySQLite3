TWEAK_NAME = libEasySQLite3
libEasySQLite3_FILES = libEasySQLite3.xm
libEasySQLite3_LDFLAGS=-lsqlite3
libEasySQLite3_FRAMEWORKS = UIKit CoreFoundation
include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
