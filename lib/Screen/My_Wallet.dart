import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/Cart.dart';
// import 'package:eshop/Screen/PaypalWebviewActivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:http/http.dart';
import 'package:paytm/paytm.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../ui/styles/DesignConfig.dart';
import '../ui/styles/Validators.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/styles/Color.dart';
import '../Helper/Constant.dart';
import '../ui/widgets/PaymentRadio.dart';
import '../Helper/Session.dart';
import '../ui/widgets/SimBtn.dart';
import '../Helper/String.dart';
import '../ui/widgets/Stripe_Service.dart';
import '../Model/Transaction_Model.dart';
import 'HomePage.dart';

class MyWallet extends StatefulWidget {
  const MyWallet({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateWallet();
  }
}

class StateWallet extends State<MyWallet> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formkey1 = GlobalKey<FormState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  List<TransactionModel> tempList = [];
  List<TransactionModel> tempList1 = [];
  TextEditingController? amtC, msgC;
  List<String?> paymentMethodList = [];
  List<String> paymentIconList = [
    'assets/images/paypal.svg',
    'assets/images/rozerpay.svg',
    'assets/images/paystack.svg',
    'assets/images/flutterwave.svg',
    'assets/images/stripe.svg',
    'assets/images/paytm.svg',
  ];
  List<RadioModel> payModel = [];
  bool? paypal, razorpay, paumoney, paystack, flutterwave, stripe, paytm;
  String? razorpayId,
      paystackId,
      stripeId,
      stripeSecret,
      stripeMode = "test",
      stripeCurCode,
      paytmMerId,
      paytmMerKey;

  int? selectedMethod;
  String? payMethod;
  StateSetter? dialogState;
  bool _isProgress = false;
  late Razorpay _razorpay;
  List<TransactionModel> tranList = [];
  List<TransactionModel> withdTranList = [];
  int offset = 0;
  int offset1 = 0;
  int total = 0;
  int total1 = 0;
  bool isLoadingmore = true, _isLoading = true, payTesting = true;
  // final paystackPlugin = PaystackPlugin();
  TextEditingController? amtC1, bankDetailC;
  bool isWithdraw = false;

  @override
  void initState() {
    super.initState();
    selectedMethod = null;
    payMethod = null;
    Future.delayed(Duration.zero, () {
      paymentMethodList = [
        getTranslated(context, 'PAYPAL_LBL'),
        getTranslated(context, 'RAZORPAY_LBL'),
        getTranslated(context, 'PAYSTACK_LBL'),
        getTranslated(context, 'FLUTTERWAVE_LBL'),
        getTranslated(context, 'STRIPE_LBL'),
        getTranslated(context, 'PAYTM_LBL'),
      ];
      _getpaymentMethod();
    });

    controller.addListener(_scrollListener);
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(CurvedAnimation(
      parent: buttonController!,
      curve: const Interval(
        0.0,
        0.150,
      ),
    ));
    amtC = TextEditingController();
    msgC = TextEditingController();
    amtC1 = TextEditingController();
    bankDetailC = TextEditingController();
    getTransaction();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  getAppBar() {
    return AppBar(
      elevation: 0,
      titleSpacing: 0,
      backgroundColor: Theme.of(context).colorScheme.white,
      leading: Builder(builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => Navigator.of(context).pop(),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: colors.primary,
              ),
            ),
          ),
        );
      }),
      title: Text(
        getTranslated(context, 'MYWALLET')!,
        style: const TextStyle(
            color: colors.primary, fontWeight: FontWeight.normal),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 5.0),
          child: IconButton(
            onPressed: () {
              openFilterBottomSheet();
              // filterDialog();
            },
            icon: const Icon(
              Icons.filter_list,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  void openFilterBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return Wrap(
              children: [
                bottomSheetHandle(context),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40.0),
                      topRight: Radius.circular(40.0),
                    ),
                    color: Theme.of(context).colorScheme.white,
                  ),
                  padding: EdgeInsetsDirectional.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      bottomsheetLabel('FILTER', context),
                      Flexible(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 20.0, end: 20.0, bottom: 15.0),
                                child: Container(
                                  width: deviceWidth! - 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Theme.of(context).colorScheme.gray,
                                  ),
                                  child: TextButton(
                                      child: Text(
                                          getTranslated(
                                              context, 'WAL_TRANS_LBL')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor
                                                      .withOpacity(0.5))),
                                      onPressed: () {
                                        setState(() {
                                          isWithdraw = false;
                                          isLoadingmore = true;
                                          _isLoading = true;
                                          offset = 0;
                                          total = 0;
                                          tranList.clear();
                                          getTransaction();
                                        });

                                        Navigator.pop(context, 'option1');
                                      }),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 20.0, end: 20.0, bottom: 15.0),
                                child: Container(
                                  width: deviceWidth! - 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Theme.of(context).colorScheme.gray,
                                  ),
                                  child: TextButton(
                                      child: Text(
                                          getTranslated(
                                              context, 'WITHD_WAL_TRANS_LBL')!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor
                                                      .withOpacity(0.5))),
                                      onPressed: () {
                                        setState(() {
                                          isWithdraw = true;
                                          isLoadingmore = true;
                                          _isLoading = true;
                                          offset1 = 0;
                                          total1 = 0;
                                          withdTranList.clear();
                                        });

                                        getWithdrawalTransaction();

                                        Navigator.pop(context, 'option2');
                                      }),
                                ),
                              ),
                            ]),
                      ),
                    ],
                  ),
                ),
              ],
            );
          });
        });
  }

  /* void filterDialog() {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.white,
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      builder: (builder) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 19.0, bottom: 16.0),
                            child: Text(
                              getTranslated(context, 'FILTER')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6!
                                  .copyWith(
                                  color:
                                  Theme.of(context).colorScheme.fontColor),
                            )),
                      ),
                      InkWell(
                        onTap: () {
                          sortBy = '';
                          orderBy = 'DESC';
                          if (mounted) {
                            setState(() {
                              _isLoading = true;
                              total = 0;
                              offset = 0;
                              productList.clear();
                            });
                          }
                          getProduct("1");
                          Navigator.pop(context, 'option 1');
                        },
                        child: Container(
                          width: deviceWidth,
                          color: sortBy == ''
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Text(getTranslated(context, 'TOP_RATED')!,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                  color: sortBy == ''
                                      ? Theme.of(context).colorScheme.white
                                      : Theme.of(context)
                                      .colorScheme
                                      .fontColor)),
                        ),
                      ),
                      InkWell(
                          child: Container(
                              width: deviceWidth,
                              color: sortBy == 'p.date_added' && orderBy == 'DESC'
                                  ? colors.primary
                                  : Theme.of(context).colorScheme.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              child: Text(getTranslated(context, 'F_NEWEST')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                      color: sortBy == 'p.date_added' &&
                                          orderBy == 'DESC'
                                          ? Theme.of(context).colorScheme.white
                                          : Theme.of(context)
                                          .colorScheme
                                          .fontColor))),
                          onTap: () {
                            sortBy = 'p.date_added';
                            orderBy = 'DESC';
                            if (mounted) {
                              setState(() {
                                _isLoading = true;
                                total = 0;
                                offset = 0;
                                productList.clear();
                              });
                            }
                            getProduct("0");
                            Navigator.pop(context, 'option 1');
                          }),
                    ]),
              );
            });
      },
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getAppBar(),
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : Stack(
                    children: <Widget>[
                      showContent(),
                      showCircularProgress(_isProgress, colors.primary),
                    ],
                  )
            : noInternet(context));
  }

  withDrawDailog() {
    return dialogAnimate(
        context,
        AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(25.0))),
          title: Text(getTranslated(context, 'SEND_WITHD_REQ_LBL')!,
              textAlign: TextAlign.center),
          content: StatefulBuilder(builder: (context, StateSetter setStater) {
            return Form(
              key: _formkey1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25)),
                        height: 50,
                        child: TextFormField(
                          controller: amtC1,
                          autofocus: false,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                          validator: (value) => validateField(
                              value!, getTranslated(context, 'FIELD_REQUIRED')),
                          enabled: true,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.gray),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.fromLTRB(15.0, 10.0, 10, 10.0),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            fillColor: Theme.of(context).colorScheme.gray,
                            filled: true,
                            isDense: true,
                            hintText: getTranslated(context, 'WIDTH_AMT_LBL')!,
                            hintStyle:
                                Theme.of(context).textTheme.bodyText2!.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                    ),
                          ),
                        ),
                      )),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: TextFormField(
                        controller: bankDetailC,
                        autofocus: false,
                        style: Theme.of(context).textTheme.bodyText1!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor),
                        validator: (value) => validateField(
                            value!, getTranslated(context, 'FIELD_REQUIRED')),
                        enabled: true,
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.multiline,
                        maxLines: 7,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.gray,
                                width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.gray,
                                width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.gray,
                                width: 1),
                          ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(15.0, 10.0, 10, 10.0),
                          fillColor: Theme.of(context).colorScheme.gray,
                          filled: true,
                          isDense: true,
                          hintText: getTranslated(context, 'BANK_DET_LBL')!,
                          hintStyle:
                              Theme.of(context).textTheme.bodyText2!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.7),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.normal,
                                  ),
                        ),
                      )),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 15.0, top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                  padding: EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 20, end: 20),
                                  // width: double.maxFinite,
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    //color: colors.primary,
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5.0)),
                                  ),
                                  child: Text(getTranslated(context, 'CANCEL')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                            fontWeight: FontWeight.bold,
                                          )))),
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                final form = _formkey1.currentState!;
                                if (form.validate()) {
                                  form.save();
                                  setStater(
                                    () {
                                      Navigator.pop(context);
                                    },
                                  );
                                  setState(() {
                                    _isProgress = true;
                                  });

                                  sendWithdrawRequest();
                                }
                              },
                              child: Container(
                                  padding: EdgeInsetsDirectional.only(
                                      top: 10, bottom: 10, start: 25, end: 25),
                                  //width: double.maxFinite,
                                  height: 40,
                                  alignment: FractionalOffset.center,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5.0)),
                                  ),
                                  child: Text(getTranslated(context, 'SEND')!,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white,
                                            fontWeight: FontWeight.bold,
                                          )))),
                        ],
                      ))
                ],
              ),
            );
          }),
        ));
  }

  /*_showDialog1() async {
    await dialogAnimate(
        context,
        AlertDialog(
          contentPadding: const EdgeInsets.all(0.0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(
                25.0,
              ),
            ),
          ),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20.0,
                    20.0,
                    0,
                    2.0,
                  ),
                  child: Text(
                    "Send Request",
                    style: Theme.of(this.context).textTheme.subtitle1!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                  ),
                ),
                const Divider(),
                Form(
                  key: _formkey1,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          0,
                          20.0,
                          0,
                        ),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          validator: (value) => validateField(value!, ""),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: "Withdrawal Amount",
                            hintStyle: Theme.of(context)
                                .textTheme
                                .subtitle1!
                                .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack2,
                                  fontWeight: FontWeight.normal,
                                ),
                          ),
                          controller: amtC,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20.0,
                          0,
                          20.0,
                          0,
                        ),
                        child: TextFormField(
                          validator: (value) => validateField(value!, ""),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: "Bank Details",
                            hintStyle: Theme.of(this.context)
                                .textTheme
                                .subtitle1!
                                .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack2,
                                  fontWeight: FontWeight.normal,
                                ),
                          ),
                          controller: bankDetailC,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Cancel",
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
                child: Text(
                  "Send",
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                onPressed: () {
                  final form = _formkey1.currentState!;
                  if (form.validate()) {
                    form.save();
                    setState(
                      () {
                        Navigator.pop(context);
                      },
                    );
                    //sendRequest();
                  }
                })
          ],
        ));
  }*/

  Widget paymentItem(int index) {
    if (index == 0 && paypal! ||
        index == 1 && razorpay! ||
        index == 2 && paystack! ||
        index == 3 && flutterwave! ||
        index == 4 && stripe! ||
        index == 5 && paytm!) {
      return InkWell(
        onTap: () {
          if (mounted) {
            dialogState!(() {
              selectedMethod = index;
              payMethod = paymentMethodList[selectedMethod!];
              for (var element in payModel) {
                element.isSelected = false;
              }
              payModel[index].isSelected = true;
            });
          }
        },
        child: RadioItem(payModel[index]),
      );
    } else {
      return Container();
    }
  }

  Future<void> sendWithdrawRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          AMOUNT: amtC1!.text.toString(),
          PAYMENT_ADD: bankDetailC!.text.toString()
        };

        Response response = await post(
          setSendWithdrawReqApi,
          body: parameter,
          headers: headers,
        ).timeout(
          const Duration(
            seconds: timeOut,
          ),
        );

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          amtC1!.clear();
          bankDetailC!.clear();
          UserProvider userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider
              .setBalance(double.parse(getdata["data"]).toStringAsFixed(2));
        }
        if (mounted)
          setState(() {
            _isProgress = false;
          });
        setSnackbar(msg, context);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, "somethingMSg")!, context);
        setState(
          () {
            _isProgress = false;
          },
        );
      }
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
            _isProgress = false;
          },
        );
      }
    }

    return;
  }

  Future<void> sendRequest(String? txnId, String payMethod) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      String orderId =
          "wallet-refill-user-$CUR_USERID-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}";
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          AMOUNT: amtC!.text.toString(),
          TRANS_TYPE: WALLET,
          TYPE: CREDIT,
          MSG: (msgC!.text == '' || msgC!.text.isEmpty)
              ? "Added through wallet"
              : msgC!.text,
          TXNID: txnId,
          ORDER_ID: orderId,
          STATUS: "Success",
          PAYMENT_METHOD: payMethod.toLowerCase()
        };
        debugPrint("param****$parameter");
        apiBaseHelper.postAPICall(addTransactionApi, parameter).then((getdata) {
          debugPrint("getdata wallet****$getdata");
          bool error = getdata["error"];
          String msg = getdata["message"];

          if (!error) {
            // CUR_BALANCE = double.parse(getdata["new_balance"]).toStringAsFixed(2);
            UserProvider userProvider =
                Provider.of<UserProvider>(context, listen: false);
            userProvider.setBalance(double.parse(getdata["new_balance"])
                .toStringAsFixed(2)
                .toString());
            isWithdraw = false;
            _isLoading = true;
            amtC!.clear();
            offset = 0;
            total = 0;
            tranList.clear();
            getTransaction();
          }

          setSnackbar(msg, context);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);

        setState(() {
          _isProgress = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
          _isProgress = false;
        });
      }
    }

    return;
  }

  _showDialog() async {
    bool payWarn = false;
    await dialogAnimate(context,
        StatefulBuilder(builder: (BuildContext context, StateSetter setStater) {
      dialogState = setStater;
      return AlertDialog(
        contentPadding: const EdgeInsets.all(0.0),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                  child: Text(
                    getTranslated(context, 'ADD_MONEY')!,
                    style: Theme.of(this.context).textTheme.subtitle1!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                  )),
              Divider(color: Theme.of(context).colorScheme.lightBlack),
              Form(
                key: _formkey,
                child: Flexible(
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                        Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.normal),
                              keyboardType: TextInputType.number,
                              validator: (val) => validateField(val!,
                                  getTranslated(context, 'FIELD_REQUIRED')),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, "AMOUNT"),
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.normal),
                              ),
                              controller: amtC,
                            )),
                        Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.normal),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, 'MSG'),
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack,
                                        fontWeight: FontWeight.normal),
                              ),
                              controller: msgC,
                            )),
                        //Divider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 10, 20.0, 5),
                          child: Text(
                            getTranslated(context, 'SELECT_PAYMENT')!,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                        const Divider(),
                        payWarn
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Text(
                                  getTranslated(context, 'payWarning')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(color: Colors.red),
                                ),
                              )
                            : Container(),

                        paypal == null
                            ? const Center(
                                child: CircularProgressIndicator(
                                color: colors.primary,
                              ))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: getPayList()),
                      ])),
                ),
              )
            ]),
        actions: <Widget>[
          TextButton(
              child: Text(
                getTranslated(context, 'CANCEL')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.lightBlack,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(context);
              }),
          TextButton(
              child: Text(
                getTranslated(context, 'SEND')!,
                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                final form = _formkey.currentState!;
                debugPrint("paymethod****$payMethod");
                if (form.validate() && amtC!.text != '0') {
                  form.save();
                  if (payMethod == null) {
                    dialogState!(() {
                      payWarn = true;
                    });
                  } else {
                    if (payMethod!.trim() ==
                        getTranslated(context, 'STRIPE_LBL')!.trim()) {
                      stripePayment(int.parse(amtC!.text));
                    } else if (payMethod!.trim() ==
                        getTranslated(context, 'RAZORPAY_LBL')!.trim()) {
                      razorpayPayment(double.parse(amtC!.text));
                    } else if (payMethod!.trim() ==
                        getTranslated(context, 'PAYSTACK_LBL')!.trim()) {
                      // paystackPayment(context, int.parse(amtC!.text));
                    } else if (payMethod ==
                        getTranslated(context, 'PAYTM_LBL')) {
                      paytmPayment(double.parse(amtC!.text));
                    } else if (payMethod ==
                        getTranslated(context, 'PAYPAL_LBL')) {
                      paypalPayment((amtC!.text).toString());
                    } else if (payMethod ==
                        getTranslated(context, 'FLUTTERWAVE_LBL')) {
                      flutterwavePayment(amtC!.text);
                    }
                    Navigator.pop(context);
                  }
                }
              })
        ],
      );
    }));
  }

  List<Widget> getPayList() {
    return paymentMethodList
        .asMap()
        .map(
          (index, element) => MapEntry(index, paymentItem(index)),
        )
        .values
        .toList();
  }

  Future<void> paypalPayment(String amt) async {
    String orderId =
        "wallet-refill-user-$CUR_USERID-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}";

    try {
      var parameter = {USER_ID: CUR_USERID, ORDER_ID: orderId, AMOUNT: amt};

      apiBaseHelper.postAPICall(paypalTransactionApi, parameter).then(
          (getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          String? data = getdata["data"];

          // Navigator.push(
          //     context,
          //     CupertinoPageRoute(
          //         builder: (BuildContext context) => PaypalWebview(
          //               url: data,
          //               from: "wallet",
          //             )))
          //   ..then((value) async {
          //     await getUserWalletBalanceFromTransactionAPI();
          //   });
          // ;
        } else {
          setSnackbar(msg!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  Future<void> flutterwavePayment(String price) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            _isProgress = true;
          });
        }

        var parameter = {
          AMOUNT: price,
          USER_ID: CUR_USERID,
        };
        apiBaseHelper.postAPICall(flutterwaveApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["link"];
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //         builder: (BuildContext context) => PaypalWebview(
            //               url: data,
            //               from: "wallet",
            //               amt: amtC!.text.toString(),
            //               msg: msgC!.text,
            //             ))).then((value) async {
            //   /*isWithdraw=false;
            //   _isLoading=true;
            //   amtC!.clear();
            //   offset = 0;
            //   total = 0;
            //   tranList.clear();
            //   getTransaction();*/

            //   await getUserWalletBalanceFromTransactionAPI();
            // });
          } else {
            setSnackbar(msg!, context);
          }
          setState(() {
            _isProgress = false;
          });
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setState(() {
          _isProgress = false;
        });
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  void paytmPayment(double price) async {
    String? paymentResponse;
    setState(() {
      _isProgress = true;
    });
    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    String callBackUrl =
        '${payTesting ? 'https://securegw-stage.paytm.in' : 'https://securegw.paytm.in'}/theia/paytmCallback?ORDER_ID=$orderId';

    var parameter = {
      AMOUNT: price.toString(),
      USER_ID: CUR_USERID,
      ORDER_ID: orderId
    };

    try {
      apiBaseHelper.postAPICall(getPytmChecsumkApi, parameter).then((getdata) {
        String? txnToken;
        setState(() {
          txnToken = getdata["txn_token"];
        });

        var paytmResponse = Paytm.payWithPaytm(
            callBackUrl: callBackUrl,
            mId: paytmMerId!,
            orderId: orderId,
            txnToken: txnToken!,
            txnAmount: price.toString(),
            staging: payTesting);

        paytmResponse.then((value) {
          setState(() async {
            _isProgress = false;

            if (value['error']) {
              paymentResponse = value['errorMessage'];
            } else {
              if (value['response'] != null) {
                paymentResponse = value['response']['STATUS'];
                if (paymentResponse == "TXN_SUCCESS") {
                  //sendRequest(orderId, "Paytm");
                  setSnackbar('Transaction Successful', context);
                  if (mounted) {
                    setState(() {
                      _isProgress = false;
                    });
                  }
                  await getUserWalletBalanceFromTransactionAPI();
                }
              }
            }

            setSnackbar(paymentResponse!, context);
          });
        });
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  stripePayment(
    int price,
  ) async {
    if (mounted) {
      setState(() {
        _isProgress = true;
      });
    }
    debugPrint("stripe cur code***$stripeCurCode");
    var response = await StripeService.payWithPaymentSheet(
        amount: (price * 100).toString(),
        currency: stripeCurCode,
        from: 'wallet',
        context: context);

    if (mounted) {
      setState(() {
        _isProgress = false;
      });
    }

    debugPrint("response****${response.status}");
    if (response.status == 'succeeded') {
      debugPrint("sucess ");
      // sendRequest(stripePayId!, "Stripe");
      setSnackbar(response.message!, context);
      if (mounted) {
        setState(() {
          _isProgress = false;
        });
      }
      await getUserWalletBalanceFromTransactionAPI();
    } else {
      debugPrint("unsucess ");

      setSnackbar(response.message!, context);
    }
    setSnackbar(response.message!, context);
  }

/*  stripePayment(int price) async {
    if (mounted) {
      setState(() {
        _isProgress = true;
      });
    }

    debugPrint("price****$price****$stripeCurCode***");

    var response = await StripeService.payWithPaymentSheet(
        amount: (price * 100).toString(),
        currency: stripeCurCode,
        from: "wallet");



    if (response.status == 'succeeded') {
      debugPrint("stripePayId****$stripePayId");
     // sendRequest(stripePayId!, "Stripe");
      isWithdraw=false;
      _isLoading=true;
      amtC!.clear();
      offset = 0;
      total = 0;
      tranList.clear();
      getTransaction();
      setSnackbar(response.message!, context);
    } else {
      setSnackbar(response.message!, context);
    }
    if (mounted) {
      setState(() {
        _isProgress = false;
      });
    }
  }*/

  // paystackPayment(BuildContext context, int price) async {
  //   debugPrint("in paystack***");
  //   if (mounted) {
  //     setState(() {
  //       _isProgress = true;
  //     });
  //   }
  //   await paystackPlugin.initialize(publicKey: paystackId!);

  //   String? email = context.read<UserProvider>().email;

  //   Charge charge = Charge()
  //     ..amount = price
  //     ..reference = _getReference()
  //     ..putMetaData('order_id',
  //         'wallet-refill-user-$CUR_USERID-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}')
  //     ..email = email;

  //   try {
  //     CheckoutResponse response = await paystackPlugin.checkout(
  //       context,
  //       method: CheckoutMethod.card,
  //       charge: charge,
  //     );
  //     if (response.status) {

  //       if (mounted) {
  //         //setSnackbar('Transaction Successful', context);
  //         setState(() {
  //           _isProgress = false;
  //         });
  //       }
  //       await getUserWalletBalanceFromTransactionAPI();
  //       //sendRequest(response.reference, "Paystack");
  //     } else {
  //       setSnackbar(response.message, context);
  //       if (mounted) {
  //         setState(() {
  //           _isProgress = false;
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) setState(() => _isProgress = false);
  //     rethrow;
  //   }
  // }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    //placeOrder(response.paymentId);
    setSnackbar('Amount added successfully', context);
    if (mounted) {
      setState(() {
        _isProgress = false;
      });
    }
    await getUserWalletBalanceFromTransactionAPI();
    //sendRequest(response.paymentId, "RazorPay");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setSnackbar(response.message!, context);
    if (mounted) {
      setState(() {
        _isProgress = false;
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("EXTERNAL_WALLET: ${response.walletName!}");
  }

  razorpayPayment(double price) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    String? contact = settingsProvider.mobile;
    String? email = settingsProvider.email;

    double amt = price * 100;

    if (contact != '' && email != '') {
      if (mounted) {
        setState(() {
          _isProgress = true;
        });
      }

      String orderId =
          'wallet-refill-user-$CUR_USERID-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';

      var options = {
        KEY: razorpayId,
        AMOUNT: amt.toString(),
        NAME: settingsProvider.userName,
        'prefill': {CONTACT: contact, EMAIL: email},
        'notes': {'order_id': orderId}
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      if (email == '') {
        setSnackbar(getTranslated(context, 'emailWarning')!, context);
      } else if (contact == '') {
        setSnackbar(getTranslated(context, 'phoneWarning')!, context);
      }
    }
  }

  listItem1(int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "${getTranslated(context, 'AMOUNT')!} : ${getPriceFormat(context, double.parse(withdTranList[index].amt!))!}",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(withdTranList[index].dateCreated!),
                      ],
                    ),
                    const Divider(),
                    Text(
                        "${getTranslated(context, 'ID_LBL')!} : ${withdTranList[index].id!}"),
                    Text("Payment Address : ${withdTranList[index].payAdd!}"),
                  ]))),
    );
  }

  listItem(int index) {
    Color back;
    if (tranList[index].type == "credit") {
      back = Colors.green;
    } else {
      back = Colors.red;
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "${getTranslated(context, 'AMOUNT')!} : ${getPriceFormat(context, double.parse(tranList[index].amt!))!}",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(tranList[index].date!),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                            "${getTranslated(context, 'ID_LBL')!} : ${tranList[index].id!}"),
                        const Spacer(),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: back,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4.0))),
                          child: Text(
                            tranList[index].type!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.white),
                          ),
                        )
                      ],
                    ),
                    tranList[index].msg != null &&
                            tranList[index].msg!.isNotEmpty
                        ? Text(
                            "${getTranslated(context, 'MSG')!} : ${tranList[index].msg!}")
                        : Container(),
                  ]))),
    );
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            _playAnimation();

            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                if (!isWithdraw) {
                  getTransaction();
                } else {
                  getWithdrawalTransaction();
                }
              } else {
                await buttonController!.reverse();
                setState(() {});
              }
            });
          },
        )
      ]),
    );
  }

  Future<void> getWithdrawalTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset1.toString(),
          USER_ID: CUR_USERID,
        };

        debugPrint("widh****$parameter");
        apiBaseHelper.postAPICall(getWithdrawReqApi, parameter).then((getdata) {
          debugPrint("widh getdata****$getdata");
          bool error = getdata["error"];
          // String msg = getdata["message"];

          if (!error) {
            total1 = int.parse(getdata["total"]);
            //getdata.containsKey("balance");

            if ((offset1) < total1) {
              tempList1.clear();
              var data = getdata["data"];
              tempList1 = (data as List)
                  .map((data) => TransactionModel.fromWithdrawJson(data))
                  .toList();

              withdTranList.addAll(tempList1);

              offset1 = offset1 + perPage;
            }
          } else {
            isLoadingmore = false;
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }

    return;
  }

  Future<void> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
          TRANS_TYPE: WALLET
        };
        apiBaseHelper.postAPICall(getWalTranApi, parameter).then((getdata) {
          bool error = getdata["error"];
          // String msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata["total"]);
            getdata.containsKey("balance");

            Provider.of<UserProvider>(context, listen: false)
                .setBalance(getdata["balance"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
              setState(() {});
            }
          } else {
            isLoadingmore = false;
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
              _isProgress = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }

    return;
  }

  Future<void> getUserWalletBalanceFromTransactionAPI() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      await Future.delayed(Duration(seconds: 1));
      try {
        var parameter = {
          LIMIT: '1',
          OFFSET: '0',
          USER_ID: CUR_USERID,
          TRANS_TYPE: WALLET
        };

        var response =
            await post(getWalTranApi, headers: headers, body: parameter)
                .timeout(const Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata['error'];

          if (!error) {
            debugPrint("balance*****${getdata['balance']}");
            Provider.of<UserProvider>(context, listen: false)
                .setBalance(getdata['balance']);
          }
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      } catch (e) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }

    return;
  }

  Future<void> getRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };
        apiBaseHelper.postAPICall(getWalTranApi, parameter).then((getdata) {
          bool error = getdata["error"];
          // String msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromReqJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }

    return;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    controller.dispose();
    amtC!.dispose();
    amtC1!.dispose();
    bankDetailC!.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _refresh() {
    if (!isWithdraw) {
      setState(() {
        _isLoading = true;
      });
      offset = 0;
      total = 0;
      tranList.clear();
      return getTransaction();
    } else {
      setState(() {
        _isLoading = true;
      });
      offset1 = 0;
      total1 = 0;
      withdTranList.clear();
      return getWithdrawalTransaction();
    }
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        setState(() {
          isLoadingmore = true;
          if (!isWithdraw) {
            if (offset < total) getTransaction();
          } else {
            if (offset1 < total1) getWithdrawalTransaction();
          }
        });
      }
    }
  }

  Future<void> _getpaymentMethod() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          TYPE: PAYMENT_METHOD,
        };
        apiBaseHelper.postAPICall(getSettingApi, parameter).then(
            (getdata) async {
          bool error = getdata["error"];

          if (!error) {
            var data = getdata["data"];

            var payment = data["payment_method"];

            paypal = payment["paypal_payment_method"] == "1" ? true : false;
            paumoney =
                payment["payumoney_payment_method"] == "1" ? true : false;
            flutterwave =
                payment["flutterwave_payment_method"] == "1" ? true : false;
            razorpay = payment["razorpay_payment_method"] == "1" ? true : false;
            paystack = payment["paystack_payment_method"] == "1" ? true : false;
            stripe = payment["stripe_payment_method"] == "1" ? true : false;
            paytm = payment["paytm_payment_method"] == "1" ? true : false;

            if (razorpay!) razorpayId = payment["razorpay_key_id"];
            if (paystack!) {
              paystackId = payment["paystack_key_id"];
            }
            if (stripe!) {
              stripeId = payment['stripe_publishable_key'];
              stripeSecret = payment['stripe_secret_key'];
              stripeCurCode = payment['stripe_currency_code'];
              stripeMode = payment['stripe_mode'] ?? 'test';
              StripeService.secret = stripeSecret;
              // StripeService.init(stripeId, stripeMode);
            }
            if (paytm!) {
              paytmMerId = payment['paytm_merchant_id'];
              paytmMerKey = payment['paytm_merchant_key'];
              payTesting =
                  payment['paytm_payment_mode'] == 'sandbox' ? true : false;
            }

            for (int i = 0; i < paymentMethodList.length; i++) {
              payModel.add(RadioModel(
                  isSelected: i == selectedMethod ? true : false,
                  name: paymentMethodList[i],
                  img: paymentIconList[i]));
            }
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          if (dialogState != null) dialogState!(() {});
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  showContent() {
    return RefreshIndicator(
        color: colors.primary,
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          controller: controller,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                          Text(
                            " ${getTranslated(context, 'CURBAL_LBL')!}",
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                        return Text(
                            getPriceFormat(context,
                                double.parse(userProvider.curBalance))!,
                            style: Theme.of(context)
                                .textTheme
                                .headline6!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold));
                      }),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SimBtn(
                              width: 0.39,
                              height: 35,
                              title: getTranslated(context, "ADD_MONEY"),
                              onBtnSelected: () {
                                _showDialog();
                              },
                            ),
                            SimBtn(
                              width: 0.39,
                              height: 35,
                              title: getTranslated(context, 'WIDTH_MON_LBL')!,
                              onBtnSelected: () {
                                //_showDialog1();
                                withDrawDailog();
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            !isWithdraw
                ? tranList.isEmpty
                    ? getNoItem(context)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                getTranslated(context, 'WAL_TRANS_LBL')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold)),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: (offset < total)
                                ? tranList.length + 1
                                : tranList.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return (index == tranList.length && isLoadingmore)
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                      color: colors.primary,
                                    ))
                                  : listItem(index);
                            },
                          ),
                        ],
                      )
                : withdTranList.isEmpty
                    ? getNoItem(context)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                                getTranslated(context, 'WITHD_WAL_TRANS_LBL')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.bold)),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: (offset1 < total1)
                                ? withdTranList.length + 1
                                : withdTranList.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return (index == withdTranList.length &&
                                      isLoadingmore)
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                      color: colors.primary,
                                    ))
                                  : listItem1(index);
                            },
                          ),
                        ],
                      ),
          ]),
        ));
  }
}
