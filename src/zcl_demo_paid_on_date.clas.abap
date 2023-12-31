CLASS zcl_demo_paid_on_date DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_invoice_header,
        invoice_guid TYPE snwd_so_inv_head-node_key,
        created_at   TYPE snwd_so_inv_head-created_at,
        paid_at      TYPE snwd_so_inv_head-changed_at,
        buyer_guid   TYPE snwd_so_inv_head-buyer_guid,
      END OF ty_invoice_header .
    TYPES:
      BEGIN OF ty_invoice_item,
        item_guid     TYPE snwd_so_inv_item-node_key,
        invoice_guid  TYPE snwd_so_inv_head-node_key,
        product_guid  TYPE snwd_so_inv_item-product_guid,
        gross_amount  TYPE snwd_so_inv_item-gross_amount,
        currency_code TYPE snwd_so_inv_item-currency_code,
      END OF ty_invoice_item .
    TYPES:
      BEGIN OF ty_customer_info,
        customer_guid TYPE snwd_bpa-node_key,
        customer_id   TYPE snwd_bpa-bp_id,
        customer_name TYPE snwd_bpa-company_name,
        country       TYPE snwd_ad-country,
        postal_code   TYPE snwd_ad-postal_code,
        city          TYPE snwd_ad-city,
      END OF ty_customer_info .
    TYPES:
      tt_invoice_header TYPE STANDARD TABLE OF ty_invoice_header WITH KEY invoice_guid .
    TYPES:
      tt_invoice_item TYPE STANDARD TABLE OF ty_invoice_item .
    TYPES:
      tt_customer_info TYPE STANDARD TABLE OF ty_customer_info .

    METHODS paid_on_date
      IMPORTING
        VALUE(iv_payment_date)   TYPE d
      EXPORTING
        VALUE(et_invoice_header) TYPE tt_invoice_header
        VALUE(et_invoice_item)   TYPE tt_invoice_item
        VALUE(et_customer_info)  TYPE tt_customer_info .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_demo_paid_on_date IMPLEMENTATION.


  METHOD paid_on_date.

    DATA ls_invoice_head TYPE ty_invoice_header.
    DATA lt_invoice_item TYPE tt_invoice_item.
    DATA lt_customer_info TYPE tt_customer_info.

    DATA lv_payment_date_min TYPE timestamp.
    DATA lv_payment_date_max TYPE timestamp.

    CONVERT DATE iv_payment_date TIME '0000' INTO TIME STAMP lv_payment_date_min TIME ZONE 'UTC'.
    CONVERT DATE iv_payment_date TIME '2359' INTO TIME STAMP lv_payment_date_max TIME ZONE 'UTC'.

    " First we retrieve all invoice header
    " which were paid on the requested date
    SELECT
      node_key       AS invoice_guid
      created_at     AS created_at
      changed_at     AS paid_at
      buyer_guid
    FROM
      snwd_so_inv_head
    INTO ls_invoice_head
    WHERE
      payment_status = 'P'
      AND changed_at BETWEEN lv_payment_date_min AND lv_payment_date_max.

      CLEAR lt_invoice_item.
      CLEAR lt_customer_info.

      "get items of invoice
      SELECT
        node_key   AS item_guid
        parent_key AS invoice_guid
        product_guid
        gross_amount
        currency_code
      FROM snwd_so_inv_item
      INTO TABLE lt_invoice_item
      WHERE parent_key = ls_invoice_head-invoice_guid.


      "get information about the customers
      SELECT
       bpa~node_key     AS customer_guid
       bpa~bp_id        AS customer_id
       bpa~company_name AS customer_name
       ad~country
       ad~postal_code
       ad~city
     FROM snwd_bpa AS bpa
     JOIN snwd_ad AS ad ON ad~node_key = bpa~address_guid
     INTO TABLE lt_customer_info
     WHERE bpa~node_key = ls_invoice_head-buyer_guid.

      APPEND ls_invoice_head           TO et_invoice_header.
      APPEND LINES OF lt_invoice_item  TO et_invoice_item.
      APPEND LINES OF lt_customer_info TO et_customer_info.
    ENDSELECT.

    "remove duplicates
    SORT et_customer_info BY customer_name.
    DELETE ADJACENT DUPLICATES FROM et_customer_info.

  ENDMETHOD.
ENDCLASS.

