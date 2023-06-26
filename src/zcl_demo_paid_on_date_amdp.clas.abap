CLASS zcl_demo_paid_on_date_amdp DEFINITION
  PUBLIC
  INHERITING FROM zcl_demo_paid_on_date
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    TYPES:
      BEGIN OF ts_totals,
        customer_name TYPE snwd_company_name,
        currency_code TYPE snwd_curr_code,
        gross_amount  TYPE snwd_ttl_gross_amount,
      END OF ts_totals.

    TYPES:
      tt_totals TYPE STANDARD TABLE OF ts_totals WITH NON-UNIQUE KEY primary_key COMPONENTS customer_name currency_code.

    CLASS-METHODS:
      customer_totals_func FOR TABLE FUNCTION zi_customer_totals_func.

    METHODS:
      paid_on_date REDEFINITION,

      customer_totals_proc
        IMPORTING VALUE(date)   TYPE dats
        EXPORTING VALUE(totals) TYPE tt_totals.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_demo_paid_on_date_amdp IMPLEMENTATION.

*****************************************************************************************************************
METHOD paid_on_date BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT OPTIONS READ-ONLY
  USING snwd_so_inv_head snwd_so_inv_item snwd_bpa snwd_ad.
    --sql script
    --        VALUE(et_invoice_header) TYPE tt_invoice_header
    --        VALUE(et_invoice_item)   TYPE tt_invoice_item
    --        VALUE(et_customer_info)  TYPE tt_customer_info .

      et_invoice_header = SELECT
        node_key       AS invoice_guid,
        created_at     AS created_at,
        changed_at     AS paid_at,
        buyer_guid
      FROM
        snwd_so_inv_head
      WHERE
        payment_status = 'P'
        AND LEFT(changed_at,8) = :iv_payment_date;


     et_invoice_item =
        SELECT
          node_key   AS item_guid,
          parent_key AS invoice_guid,
          product_guid,
          gross_amount,
          currency_code
        FROM snwd_so_inv_item
        WHERE parent_key in ( select invoice_guid from :et_invoice_header );


        --get information about the customers
       et_customer_info =  SELECT DISTINCT
         bpa.node_key     AS customer_guid,
         bpa.bp_id        AS customer_id,
         bpa.company_name AS customer_name,
         ad.country,
         ad.postal_code,
         ad.city
       FROM snwd_bpa AS bpa
       JOIN snwd_ad AS ad ON ad.node_key = bpa.address_guid
       WHERE bpa.node_key in ( select buyer_guid from :et_invoice_header )
       ORDER BY company_name;

  ENDMETHOD.

*****************************************************************************************************************
  METHOD customer_totals_proc
  BY DATABASE PROCEDURE
  FOR HDB
  LANGUAGE SQLSCRIPT
  OPTIONS READ-ONLY
  USING zcl_demo_paid_on_date_amdp=>paid_on_date.

*   Call AMDP procedure
    call "ZCL_DEMO_PAID_ON_DATE_AMDP=>PAID_ON_DATE" (
      iv_payment_date   => :date,
      et_invoice_header => lt_invoice_header,
      et_invoice_item   => lt_invoice_item,
      et_customer_info  => lt_customer_info
    );

*   Merge, aggregate and return results
    totals =
      select
        customer.customer_name,
        items.currency_code,
        sum( items.gross_amount ) as gross_amount
      from :lt_invoice_item as items
      left join :lt_invoice_header as header
        on header.invoice_guid = items.invoice_guid
      left join :lt_customer_info as customer
        on customer.customer_guid = header.buyer_guid
      group by customer.customer_name,
               items.currency_code
      order by customer_name,
               currency_code;

  ENDMETHOD.

*****************************************************************************************************************
  METHOD customer_totals_func
  BY DATABASE FUNCTION
  FOR HDB
  LANGUAGE SQLSCRIPT
  OPTIONS READ-ONLY
  USING snwd_so_inv_item
        snwd_so_inv_head
        snwd_bpa.

*   Merge, aggregate and return results
    return
      select
        items.client,
        customer.company_name as customer_name,
        items.currency_code,
        sum( items.gross_amount ) as gross_amount
      from snwd_so_inv_item as items
      left join snwd_so_inv_head as header
        on  header.client   = items.client
        and header.node_key = items.parent_key
      left join snwd_bpa as customer
        on  customer.client   = header.client
        and customer.node_key = header.buyer_guid
      where header.client = :p_client
        and header.payment_status = 'P'
        and left(header.changed_at,8) = :p_date
      group by items.client,
               customer.company_name,
               items.currency_code
      order by customer_name,
               currency_code;

  endmethod.

*****************************************************************************************************************

ENDCLASS.

