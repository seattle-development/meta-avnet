DESCRIPTION = "Util scripts for hdmi"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "uz7ev-evcc-hdmi|uz7ev-evcc-quadcam-h"

FF = "files"

HDMI_FILES = " \
    file://hdmi_passthrough.sh;subdir=${FF} \
"

QUADCAM_FILES = " \
    file://isp_tune.sh;subdir=${FF} \
    file://launch_quad_cam_gstreamer.sh;subdir=${FF} \
    file://launch_one_cam_gstreamer.sh;subdir=${FF} \
    file://media_cfg.sh;subdir=${FF} \
"

SRC_URI_uz7ev-evcc-hdmi = " \
    ${HDMI_FILES} \
"

SRC_URI_uz7ev-evcc-quadcam-h = " \
    ${QUADCAM_FILES} \
    ${HDMI_FILES} \
"

do_install() {
    install -d ${D}/${ROOT_HOME}
    install -m 777 ${WORKDIR}/${FF}/* ${D}/${ROOT_HOME}
}

FILES_${PN} = "${ROOT_HOME}/*"
