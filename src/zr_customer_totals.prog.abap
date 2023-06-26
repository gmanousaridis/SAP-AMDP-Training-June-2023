*&---------------------------------------------------------------------*
*& Report zr_customer_totals
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_customer_totals.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-bxt.
  SELECTION-SCREEN SKIP 1.

  PARAMETERS:
    p_date  TYPE dats DEFAULT '20230419'.

  SELECTION-SCREEN SKIP 1.

  SELECTION-SCREEN COMMENT /20(50) TEXT-way.
  PARAMETERS:
    r_proc RADIOBUTTON GROUP rdat DEFAULT 'X',
    r_func RADIOBUTTON GROUP rdat.

  SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN END OF BLOCK b1.


START-OF-SELECTION.

  DATA lt_totals TYPE zcl_demo_paid_on_date_amdp=>tt_totals.

  CASE abap_true.

*** Fetch with AMDP Procedure ***************************************************
    WHEN r_proc.
      TRY.
          NEW zcl_demo_paid_on_date_amdp( )->customer_totals_proc(
            EXPORTING date   = p_date
            IMPORTING totals = lt_totals
           ).

        CATCH cx_amdp_execution_failed INTO DATA(lx_amdp).
          MESSAGE lx_amdp->get_text( ) TYPE 'E' DISPLAY LIKE 'S'.
      ENDTRY.

*** Fetch with AMDP Table Function **********************************************
    WHEN r_func.
      SELECT *
      FROM zi_customer_totals_func( p_date = @p_date )
      INTO TABLE @lt_totals.

  ENDCASE.

  cl_demo_output=>write_data( name = 'Customer Totals' value = lt_totals ).

  cl_demo_output=>display( ).
