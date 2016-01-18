# =================================
# setting feature enable for BOX project
# 1:open  0:close
# =================================

AUTO_TEST = 1
ifeq ($(TARGET_CPU), mips)
PRELINK_ENABLE = 1
endif
ifeq ($(TARGET_CPU), arm)
PRELINK_ENABLE = 0
endif
ifeq ($(TARGET_CPU), )
$(error ERROR USAGE - Please select the correct target cpu for TARGET_CPU)
endif
RELEASE_CODE_ENABLE = 0
# for system database release
SYSTEM_DATABASE_RELEASE_ENABLE = 0

ifeq ($(RELEASE_CODE_ENABLE),1)
DISABLE_KERNEL_MESSAGE = 1
DISABLE_SN_MESSAGE = 1
AUTO_TEST = 0
endif

TEE_ENABLE = 1
STEREO_3D_ENABLE = 1
QJY_ENABLE = 0

# Refine Partition
ifeq ($(CHIP),t12)
REFINE_PARTITION = 1
endif
ifeq ($(CHIP),a7)
REFINE_PARTITION = 1
endif
ifeq ($(CHIP),j2)
REFINE_PARTITION = 1
endif
ifeq ($(CHIP),a1)
REFINE_PARTITION = 1
endif
ifeq ($(CHIP),a3)
REFINE_PARTITION = 1
endif
ifeq ($(CHIP),amethyst)
REFINE_PARTITION = 1
endif
ifeq ($(CHIP),edison)
REFINE_PARTITION = 1
endif
ifeq ($(CHIP),nugget)
REFINE_PARTITION = 1
endif

ENABLE_HDMI_4K2K_MODE = 0
ENABLE_PHOTO_4K2K_MODE = 0

ENABLE_NEW_AUTO_NR = 1

# Middleware features
DVB_ENABLE = 1
ifeq ($(DVB_ENABLE), 1)
DVBT_SYSTEM_ENABLE = 1
DVBC_SYSTEM_ENABLE = 1
DVBS_SYSTEM_ENABLE = 1
DTMB_SYSTEM_ENABLE = 0
ISDB_SYSTEM_ENABLE = 1
endif
BRAZIL_CC_ENABLE = 1
BRAZIL_CM_NUM_SEARCH = 0
GINGA_ENABLE = 1
GINGA_LITE_ENABLE = 0
ONE_GOP_ENABLE = 1
AD_SWITCH_ENABLE = 1
LIFIA_PACKAGE_ENABLE = 0
EPG_ENABLE = 1
EPG_EED_ENABLE = 1
PVR_ENABLE = 1
OAD_ENABLE = 0
SDTT_OAD_ENABLE = 0
LOSS_SIGNAL_ALTERNATIVE_ENABLE = 0
ENABLE_DIVX_PLUS = 1
MULTIPLE_SERVICE_NAME_ENABLE = 1
PERSISTENT_NIT_CABLE_INFO_ENABLE = 0
NVOD_ENABLE=0
MHEG5_ENABLE = 0
EEPROM_HDCP_ENABLE = 0

# misc settings for Europe
SAMBA_CLIENT_ENABLE = 0
SUPPORT_EURO_HDTV = 1
VE_ENABLE = 1
AUTO_NETWORK_UPGRADE = 0
NETWORK_UPGRADE_WITH_USB = 0
ENABLE_ZRAM = 1
ENABLE_DYNSCALING = 1

# IPC flag
SECOND_ENCRYPTED_ENABLE = 1
MSTAR_TVOS = 0
MSTAR_TVOS_AN_IMG = 0
MSTAR_ANDROID = 0
MSTAR_IPC = 1
STAGECRAFT_ENABLE = 0
CINEMANOW_ENABLE = 0
NETFLIX_ENABLE = 1
IPLAYER_ENABLE = 0
WIDGETDOCK_ENABLE = 0
DLNA_DMPDMR = 1
DLNA_DMPONLY = 0
DLNA_DMRONLY = 0
SKYPE_ENABLE = 0
VUDU_ENABLE = 0
LEANBACK_ENABLE = 0
WIFI_ENABLE = 1
GALAXY_ENABLE = 0
FACEBOOK_WIDGET = 1
TWITTER_WIDGET = 1
PICASA_WIDGET = 1
FLICKR_WIDGET = 0
TERRATV_ENABLE = 0
NCL_WEBKIT_ENABLE = 0
DRMAGENT_ENABLE = 0
SQL_DB_ENABLE = 0
QTWEBKIT_ENABLE = 1
GINGA_MWB_ENABLE = 1
MSTREAMER_ENABLE = 0
OPEN_BROWSER_ENABLE = 1
DRMAGENT_ENABLE = 0
MWB_LAUNCHER_ENABLE = 1
YTTV_ENABLE = 1
INTEL_WIDI_ENABLE = 1
DIAL_ENABLE = 1
# whether to enable MWBLauncherMemoryMonitor which will restart MWBLauncher when free memory is under specified threshold
MWB_LAUNCHER_MONITOR_ENABLE = 0
HDCP_ENABLE = 0

ifeq ($(NCL_WEBKIT_ENABLE), 1)
    WEBKIT_ENABLE = 1
endif

ifneq (,$(filter 1,$(CINEMANOW_ENABLE) $(NETFLIX_ENABLE) $(LEANBACK_ENABLE)))
STAGECRAFT_ENABLE = 0
endif

ifneq (,$(filter 1,$(IPLAYER_ENABLE) $(YTTV_ENABLE)))
    MWB_LAUNCHER_ENABLE = 1
endif

ifneq (,$(filter 1,$(HBBTV_ENABLE) $(WIDGETDOCK_ENABLE) $(IPLAYER_ENABLE) $(TERRATV_ENABLE) $(FACEBOOK_WIDGET) $(TWITTER_WIDGET) $(PICASA_WIDGET) $(FLICKR_WIDGET) $(OPEN_BROWSER_ENABLE) $(GINGA_MWB_ENABLE) $(MWB_LAUNCHER_ENABLE) ))
    QTWEBKIT_ENABLE = 1
endif

ifeq ($(QTWEBKIT_ENABLE),1)
    DRMAGENT_ENABLE = 1
endif

ifeq ($(OPEN_BROWSER_ENABLE),1)
ENABLE_ZRAM = 1
endif

ifneq (,$(filter 1,$(SKYPE_ENABLE) $(STAGECRAFT_ENABLE) $(WEBKIT_ENABLE) $(VVOIP_ENABLE)))
ALSA_ENABLE = 1
endif

ifeq ($(MSTAR_TVOS),1)
    SQL_DB_ENABLE = 1
endif

ifeq ($(DRMAGENT_ENABLE),1)
    DRM_PRKEY_BUILDIN = 1
endif

# we have to force DRMAGENT_ENABLE = 0 if no APM library available
ifeq ($(MSTAR_IPC),0)
    DRMAGENT_ENABLE = 0
endif

ifneq (, $(filter 1, $(WEBKIT_ENABLE) \
                     $(QTWEBKIT_ENABLE) \
                     $(VUDU_ENABLE) \
                     $(DLNA_DMPDMR) \
                     $(DLNA_DMPONLY) \
                     $(DLNA_DMRONLY)))
MSTREAMER_ENABLE = 1
endif

ifneq (,$(filter 1,$(INTEL_WIDI_ENABLE)))
    HDCP_ENABLE = 1
endif

# =================================
# setup compiler flags
# =================================
include $(PHOTOSPHERE_ROOT)/projects/board/$(CHIP)/pcb.mk
include $(PHOTOSPHERE_ROOT)/projects/sw_cfg/ext_devices.mk
include $(PHOTOSPHERE_ROOT)/projects/sw_cfg/compile_option.mk
include $(SWCFGPATH_DAILEO)/$(PROJ_MODE)/libs.mk
include $(PHOTOSPHERE_ROOT)/projects/board/mmap.mk
