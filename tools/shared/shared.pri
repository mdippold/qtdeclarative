INCLUDEPATH += $$PWD

# The relevant tools need different bits and pieces.
# Furthermore, some of the classes require devtools, some not.

RESOURCEFILEMAPPER_SOURCES = \
    $$PWD/resourcefilemapper.cpp

RESOURCEFILEMAPPER_HEADERS = \
    $$PWD/resourcefilemapper.h

METATYPEREADER_SOURCES = \
    $$PWD/componentversion.cpp \
    $$PWD/scopetree.cpp \
    $$PWD/typedescriptionreader.cpp

METATYPEREADER_HEADERS = \
    $$PWD/componentversion.h \
    $$PWD/metatypes.h \
    $$PWD/scopetree.h \
    $$PWD/typedescriptionreader.h

QMLSTREAMWRITER_SOURCES = \
    $$PWD/qmlstreamwriter.cpp

QMLSTREAMWRITER_HEADERS = \
    $$PWD/qmlstreamwriter.h
