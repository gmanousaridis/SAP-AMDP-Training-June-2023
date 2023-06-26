@AccessControl.authorizationCheck: #NOT_REQUIRED
@ClientHandling.type: #CLIENT_DEPENDENT
@ClientHandling.algorithm : #NONE
@EndUserText.label: 'Table Function AMDP Training June 2023'

define table function zi_customer_totals_func

with parameters
  p_client : mandt @<Environment.systemField: #CLIENT,
  p_date   : dats

returns {

  client        : mandt;
  customer_name : snwd_company_name;
  currency_code : snwd_curr_code;
  gross_amount  : snwd_ttl_gross_amount @<Semantics.amount.currencyCode: 'currency_code';
  
}

implemented by method zcl_demo_paid_on_date_amdp=>customer_totals_func;

