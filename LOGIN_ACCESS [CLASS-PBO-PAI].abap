*----------------------------------------------------------------------*
***INCLUDE Z_CL_USER.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class CL_USER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS cx_application_error DEFINITION "Defines the new exception class
  INHERITING FROM cx_static_check. "It inherits the static verification of exceptions
  PUBLIC SECTION.
    DATA: error_message TYPE string. "Variable to receive the message
    "Contructor method accepts a string parameter
    METHODS: constructor IMPORTING !error_message TYPE string.
ENDCLASS.

CLASS cx_application_error IMPLEMENTATION.
  METHOD constructor. "The method calls a string message
    super->constructor( ).
    me->error_message = error_message.
  ENDMETHOD.
ENDCLASS.

CLASS cl_user DEFINITION FINAL.

  PUBLIC SECTION.

"----------------------------------------------
    METHODS:

      "Method to hash login and password
      hash_logon
        IMPORTING
          login_adm TYPE zlogin    "Login to screen 0001
          pass_adm  TYPE zpass     "Pass to screen 0001
        EXPORTING
          hashed_login TYPE zlogin "Login hashed to screen 0001
          hashed_pass TYPE  zpass "Pass hashed to screen 0001
        RAISING
          cx_abap_message_digest
          cx_application_error,

      "Method to validate login access
      access_admin
        IMPORTING
          login_adm TYPE zlogin  "Login hashed to screen 0001
          pass_adm  TYPE zpass   "Pass hashed to screen 0001
        EXPORTING
          lvl       TYPE zlvl    "Exports the lvl access from the employee
        RAISING
          cx_application_error.  " Add the custom exception here

"----------------------------------------------

  PRIVATE SECTION.

    TYPES: BEGIN OF wa_admin,       "Work Area to admin database
        key        TYPE zkey_admin, "Id Employee
        login      TYPE zlogin,     "Nickname Employee
        pass       TYPE zpass,      "Password Employee
        start_date TYPE begda,      "Hiring Date
        end_date   TYPE endda,      "Dismissal Date
        lvl_access TYPE zlvl,       "Level Access
    END OF wa_admin.

    DATA: lt_admin TYPE TABLE OF zraadmin, "Internal Table Admin
          ls_admin LIKE LINE OF lt_admin.  "Structure Line

    DATA: lvl TYPE zlvl. "Variable to receive the Level Access

ENDCLASS.

CLASS cl_user IMPLEMENTATION.

  METHOD hash_logon. "Method to hash login and password

    "Imports: login_adm, pass_adm
    "Exports: hashed_login, hashed_pass

    DATA: result1 TYPE string, "Result from hashed login
          result2 TYPE string. "Result from hashed pass

    DATA: login_str TYPE string, "Receives a char and turn to string
          pass_str  TYPE string. "Receives a char and turn to string

    login_str = login_adm. "Login Char -> ToString
    pass_str  = pass_adm.  "Pass Char -> ToString

    "----------------------------------------------------------

    "Method to hash the login
    TRY.
    cl_abap_message_digest=>calculate_hash_for_char(
      EXPORTING
        if_algorithm = 'SHA512'
        if_data      = login_str "Send the string login
      IMPORTING
        ef_hashstring = result1  "Receive the login hashed
    ).
    "Method to hash the password
    cl_abap_message_digest=>calculate_hash_for_char(
      EXPORTING
        if_algorithm = 'SHA512'
        if_data      = pass_str "Send the string pass
      IMPORTING
        ef_hashstring = result2 "Receive the pass hashed
    ).
    CATCH cx_abap_message_digest INTO DATA(lx_message_digest).
      RAISE EXCEPTION TYPE cx_application_error
        EXPORTING
          error_message = 'Encrypt Error Data.'.
    ENDTRY.

    "----------------------------------------------------------

    hashed_login = result1. "Export it: Login String ->ToChar
    hashed_pass  = result2. "Export it: Login Pass ->ToChar

  ENDMETHOD.

  METHOD access_admin. "Method to validade login access"

    "Imports: login_adm, pass_adm
    "Exports: lvl

    "Variables to receive the hashed Login from method above.
    DATA: new_login TYPE zlogin,
          new_pass TYPE zpass.
    TRY.
      me->hash_logon( "Call the self-method to hash login and pass
        EXPORTING
          login_adm  = login_adm "Send the login char
          pass_adm   = pass_adm  "Send the pass char
        IMPORTING
          hashed_login = new_login "Login Hashed
          hashed_pass  = new_pass  "Pass Hashed
      ).
    CATCH cx_abap_message_digest INTO DATA(lx_message_digest).
      " Handle the exception (e.g., log the error, set default values, etc.)
      RETURN. " Exit the method if hashing fails
    ENDTRY.

    SELECT SINGLE *           "Select a single line
      FROM zraadmin           "From the admin table
      INTO ls_admin           "Into structure line
      WHERE login = new_login "where the login hashed and the pass hashed...
      AND pass = new_pass.    "are in the table

      IF sy-subrc = 0.             "if the login and pass are found...
        lvl = ls_admin-lvl_access. "variable receives the data
      ENDIF.

ENDMETHOD.

ENDCLASS.
*----------------------------------------------------------------------*
***INCLUDE Z_HCM_TEST8_ACCESS_SCREEN_PO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module ACCESS_SCREEN_PBO OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE access_screen_pbo OUTPUT.
* SET PF-STATUS 'xxxxxxxx'.
* SET TITLEBAR 'xxx'.

  DATA: in_login TYPE zlogin, "Element Login
        in_pass TYPE zpass.   "Element Pass

  DATA: cl_admin TYPE REF TO cl_user. "Instance from Admin Class

  IF cl_admin IS INITIAL.
    CREATE OBJECT cl_admin.  "Object from Admin Class
  ENDIF.

  DATA: lv_lvl TYPE zlvl.    "Variable to receives the Level Access

  DATA: attempts TYPE i,     "Error Attempts of the user"
        attempts_num TYPE i. "Error Limit Attempts"

ENDMODULE.

*----------------------------------------------------------------------*
***INCLUDE Z_HCM_TEST8_ACCESS_SCREEN_PI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  ACCESS_SCREEN_PAI  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE access_screen_pai INPUT.

   attempts_num = 3. "Setting the number of attempts

  "Strings are lower case in the Database
    TRANSLATE in_login TO LOWER CASE.
    TRANSLATE in_pass  TO LOWER CASE.

  CASE okcode0001.    "Case button is pressed...
    WHEN 'FCT_LOGIN'. "When the button login is pressed...

      cl_admin->access_admin(    "Call access method admin
          EXPORTING
            login_adm = in_login "Send the login writen
            pass_adm = in_pass   "Send the pass writen
          IMPORTING
            lvl = lv_lvl ).      "Receive the lvl access

      IF lv_lvl = 'S'.              "If the access is Super User...
        CALL SCREEN '0002'.         "Call Admin Menu
      ELSEIF lv_lvl = 'A' or lv_lvl = 'B' or lv_lvl = 'C'. "If the access is any other...
        CALL SCREEN '0003'.         "Call Main Menu
      ELSE.                         "If the access not exists...
        attempts = attempts + 1.    "Increment the attempts number
        IF attempts = attempts_num. "If the attempts number is = error attempts
           LEAVE PROGRAM.           "Close Program
        ENDIF.
        "Display Message showing the number of the attempts.
        MESSAGE |'Errors: { attempts_num }/' { attempts } | TYPE 'S' DISPLAY LIKE 'I'.
      ENDIF.
    WHEN'FCT_EXIT1'.  "When the button exit is pressed...
       LEAVE PROGRAM. "Close Program
    ENDCASE.
ENDMODULE.
