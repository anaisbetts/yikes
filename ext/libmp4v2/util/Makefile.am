
INCLUDES = -I$(top_srcdir)


bin_PROGRAMS = mp4dump mp4extract mp4info mp4trackdump mp4tags mp4art 
check_PROGRAMS = mp4syncfiles

mp4dump_SOURCES = mp4dump.cpp mpeg4ip_getopt.h
mp4dump_LDADD = $(top_builddir)/libmp4v2.la

mp4extract_SOURCES = mp4extract.cpp mpeg4ip_getopt.h
mp4extract_LDADD = $(top_builddir)/libmp4v2.la 

mp4info_SOURCES = mp4info.cpp mpeg4ip_getopt.h
mp4info_LDADD = $(top_builddir)/libmp4v2.la

mp4trackdump_SOURCES = mp4trackdump.cpp mpeg4ip_getopt.h
mp4trackdump_LDADD = $(top_builddir)/libmp4v2.la

mp4tags_SOURCES = mp4tags.cpp mpeg4ip_getopt.h
mp4tags_LDADD = $(top_builddir)/libmp4v2.la 

mp4art_SOURCES = mp4art.cpp mpeg4ip_getopt.h
mp4art_LDADD = $(top_builddir)/libmp4v2.la

mp4syncfiles_SOURCES = mp4syncfiles.cpp
mp4syncfiles_LDADD = $(top_builddir)/libmp4v2.la

EXTRA_DIST = mp4dump60.dsp  \
	mp4info.dsp mp4tags.dsp
