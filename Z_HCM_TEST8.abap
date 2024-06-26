*&---------------------------------------------------------------------*
*& Report Z_HCM_TEST8
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_hcm_test8.

"screen system-functions variables"
DATA: okcode0001 TYPE sy-ucomm, "login screen"
      okcode0002 TYPE sy-ucomm, "admin menu"
        okcode0021 TYPE sy-ucomm, "insert admin"
      okcode0003 TYPE sy-ucomm. "main menu"

"classes"
INCLUDE z_cl_user. "user class"

"login screen"
INCLUDE z_hcm_test8_access_screen_po01.
INCLUDE z_hcm_test8_access_screen_pi01.
"admin screen"
INCLUDE z_hcm_test8_admin_screen_pbo01.
INCLUDE z_hcm_test8_admin_screen_pai01.
"menu screen"
INCLUDE z_hcm_test8_menu_screen_pboo01.
INCLUDE z_hcm_test8_menu_screen_paii01.
"insert admin screen"
INCLUDE z_before_insert_admin.
INCLUDE z_after_insert_admin.
