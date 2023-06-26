*&---------------------------------------------------------------------*
*& Report zr_paid_on_date
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
PROGRAM zr_paid_on_date.

DATA p_date TYPE d VALUE '20230419'.

DATA(lo_timer) = cl_abap_runtime=>create_hr_timer( ).
DATA(lo_info_list) = NEW zcl_demo_paid_on_date( ).

DATA(t1) = lo_timer->get_runtime( ).
lo_info_list->paid_on_date(
                      EXPORTING
                        iv_payment_date   = p_date
                      IMPORTING
                        et_invoice_header = DATA(lt_invoice_head)
                        et_invoice_item   = DATA(lt_invoice_item)
                        et_customer_info  = DATA(lt_customer_info)  ).

DATA(t2) = lo_timer->get_runtime( ).
DATA(elapsed_time) = ( t2 - t1 ) / 1000.

cl_demo_output=>next_section( title = |Runtime (ABAP): { elapsed_time } ms.| ).
cl_demo_output=>write_data( name = 'Invoice Items'  value = lt_invoice_item ).

cl_demo_output=>display( ).
