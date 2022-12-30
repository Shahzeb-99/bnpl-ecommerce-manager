// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_bnql/investor_panel/model/vendors.dart';

import '../../investor_panel/customer/payment_schedule_class.dart';
import '../../investor_panel/customer/transaction_history_class.dart';
import '../../investor_panel/dashboard/dashboard_screen.dart';

class Purchase {
  num companyProfit;
 final String customerID;
 final DocumentReference documentReferencePurchase;
 final Timestamp purchaseDate;
  final  purchaseAmount;
  final String vendorName;
  final sellingAmount;
  final String? profitPercentage;
  final totalProfit;
  final String productName;
  final String productImage;
  var outstandingBalance;
  var amountPaid;
  final String customerName;
  List<PaymentSchedule> paymentSchedule = [];
  List<TransactionHistory> transactionHistory = [];

bool isBatchOrder;

List<Investors>? investors ;
  Purchase(
      {this.investors,
        required this.customerName,
      required this.companyProfit,
      required this.customerID,
      required this.documentReferencePurchase,
      required this.vendorName,
      required this.outstandingBalance,
      required this.amountPaid,
      required this.productName,
      required this.productImage,
      this.profitPercentage,
      required this.purchaseAmount,
      required this.sellingAmount,
      this.totalProfit,
      required this.purchaseDate,required this.isBatchOrder});

  Future<void> getPaymentSchedule(String customerDocID) async {
    paymentSchedule = [];
    await documentReferencePurchase
        .collection('payment_schedule')
        .orderBy('date', descending: false)
        .get()
        .then((value) {
      for (var payment in value.docs) {
        var amount = payment.get('amount');
        Timestamp date = payment.get('date');
        bool isPaid = payment.get('isPaid');

        paymentSchedule.add(PaymentSchedule(
            remainingAmount: payment.get('remainingAmount'),
            amount: amount,
            isPaid: isPaid,
            date: date,
            paymentReference: payment.id,
            purchaseReference: documentReferencePurchase,
            customerdocID: customerDocID));
      }
    });
  }

  Future<void> getPaymentScheduleMonthlyOutstanding(
      String customerDocID) async {
    paymentSchedule = [];
    await documentReferencePurchase
        .collection('payment_schedule')
        .orderBy('date', descending: false)
        .where('date',
            isLessThanOrEqualTo:
                DateTime(DateTime.now().year, DateTime.now().month + 1, 0))
        .get()
        .then((value) {
      for (var payment in value.docs) {
        var amount = payment.get('amount');
        Timestamp date = payment.get('date');
        bool isPaid = payment.get('isPaid');

        paymentSchedule.add(PaymentSchedule(
            remainingAmount: payment.get('remainingAmount'),
            amount: amount,
            isPaid: isPaid,
            date: date,
            paymentReference: payment.id,
            purchaseReference: documentReferencePurchase,
            customerdocID: customerDocID));
      }
    });
  }

  Future<void> getPaymentScheduleMonthlyRecovery(
      String customerDocID, DashboardFilterOptions option) async {
    paymentSchedule = [];
    await documentReferencePurchase
        .collection('payment_schedule')
        .orderBy('date', descending: false)
        .get()
        .then((value) async {
      for (var payment in value.docs) {
        var amount = payment.get('amount');
        Timestamp date = payment.get('date');
        bool isPaid = payment.get('isPaid');

        await payment.reference
            .collection('transactions')
            .where('date',
                isLessThanOrEqualTo: option != DashboardFilterOptions.all
                    ? DateTime(DateTime.now().year, DateTime.now().month + 1, 0,23,59)
                    : DateTime(2100))
            .get()
            .then((value) {
          num paidAmount = 0;
          for (var transaction in value.docs) {
            paidAmount += transaction.get('remainingAmount');
          }
          if (paidAmount > 0) {
            paymentSchedule.add(PaymentSchedule(
                remainingAmount: payment.get('remainingAmount'),
                amount: amount,
                isPaid: isPaid,
                date: date,
                paymentReference: payment.id,
                purchaseReference: documentReferencePurchase,
                customerdocID: customerDocID));
          }
        });
      }
    });
  }

  Future<void> getTransactionHistory(String customerDocID) async {
    transactionHistory = [];
    await documentReferencePurchase
        .collection('transaction_history')
        .orderBy('date', descending: false)
        .get()
        .then((value) {
      for (var payment in value.docs) {
        var amount = payment.get('amount');
        Timestamp date = payment.get('date');

        transactionHistory.add(TransactionHistory(amount: amount, date: date));
      }
    });
  }

  Future<void> getTransactionHistoryRecovery(
      String customerDocID, bool isThisMonth) async {
    transactionHistory = [];
    await documentReferencePurchase
        .collection('transaction_history')
        .where('date',
            isLessThanOrEqualTo:
                DateTime(DateTime.now().year, DateTime.now().month + 1, 0))
        .where('date',
            isGreaterThanOrEqualTo: isThisMonth
                ? DateTime(DateTime.now().year, DateTime.now().month, 1,23,59)
                : DateTime(DateTime.now().year, DateTime.now().month - 5, 1,23,59))
        .orderBy('date', descending: false)
        .get()
        .then((value) {
      for (var payment in value.docs) {
        var amount = payment.get('amount');
        Timestamp date = payment.get('date');

        transactionHistory.add(TransactionHistory(amount: amount, date: date));
      }
    });
  }

  updateCustomTransaction({required int amount}) async {
    final cloud = FirebaseFirestore.instance;

    await cloud.collection('investorCustomers').doc(customerID).update({
      'outstanding_balance': FieldValue.increment(-amount),
      'paid_amount': FieldValue.increment(amount),
    });

    await documentReferencePurchase.update({
      'outstanding_balance': FieldValue.increment(-amount),
      'paid_amount': FieldValue.increment(amount),
    });
    cloud.collection('investorFinancials').doc('finance').update({
      'amount_paid': FieldValue.increment(amount),
      'outstanding_balance': FieldValue.increment(-amount),
    });

    if (amount > companyProfit) {
      cloud.collection('investorFinancials').doc('finance').update({
        'companyProfit': FieldValue.increment(companyProfit),
      }).whenComplete(() {
        amount -= companyProfit.toInt();
       
        documentReferencePurchase.update({'companyProfit':0}).whenComplete(() {companyProfit=0;});
        cloud.collection('investorFinancials').doc('finance').update({
          'cash_available': FieldValue.increment(amount),
        });
       // investorReference
          //  .update({'currentBalance': FieldValue.increment(amount)});
      });
    } else {
      cloud.collection('investorFinancials').doc('finance').update({
        'company_profit': FieldValue.increment(amount),
      }).whenComplete(() {
       // investorReference.update({'company_profit':FieldValue.increment(amount)});
        
        documentReferencePurchase.update({'companyProfit':FieldValue.increment(-amount)}).whenComplete(() {companyProfit -= amount;});
      });
    }
  }
  updateCustomBatchTransaction({required int amount}) async {
    final cloud = FirebaseFirestore.instance;

    await cloud.collection('investorCustomers').doc(customerID).update({
      'outstanding_balance': FieldValue.increment(-amount),
      'paid_amount': FieldValue.increment(amount),
    });

    await documentReferencePurchase.update({
      'outstanding_balance': FieldValue.increment(-amount),
      'paid_amount': FieldValue.increment(amount),
    });
    cloud.collection('investorFinancials').doc('finance').update({
      'amount_paid': FieldValue.increment(amount),
      'outstanding_balance': FieldValue.increment(-amount),
    });

    if (amount > companyProfit) {
      cloud.collection('investorFinancials').doc('finance').update({
        'companyProfit': FieldValue.increment(companyProfit),
      }).whenComplete(() {
        amount -= companyProfit.toInt();

        documentReferencePurchase.update({'companyProfit':0}).whenComplete(() {companyProfit=0;});
        cloud.collection('investorFinancials').doc('finance').update({
          'cash_available': FieldValue.increment(amount),
        });
        for(var investor in investors!){

          int amountDivided=((amount/100)*investor.percentageInvestment!).toInt();
          investor.investorReference
              ?.update({'currentBalance': FieldValue.increment(amountDivided)});

        }
      });
    } else {
      cloud.collection('investorFinancials').doc('finance').update({
        'company_profit': FieldValue.increment(amount),
      }).whenComplete(() {
        for(var investor in investors!){

          investor.investorReference?.update({'company_profit':FieldValue.increment((amount/100)*investor.percentageInvestment!)});
        }

        documentReferencePurchase.update({'companyProfit':FieldValue.increment(-amount)}).whenComplete(() {companyProfit -= amount;});
      });
    }
  }

  void addTransaction({required int amount,required DateTime dateTime}) {
    documentReferencePurchase.collection('transaction_history').add(
      {
        'amount': amount,
        'date': Timestamp.fromDate(dateTime),
      },
    );
    for(var investor in investors!){

      investor.investorReference?.update({
        'outstandingBalance': FieldValue.increment(-((amount/100)*investor.percentageInvestment!)),
        'amountPaid': FieldValue.increment((amount/100)*investor.percentageInvestment!),
      });
      investor.investorReference?.collection('transactions').add({
        'date': Timestamp.fromDate(dateTime),
        'amount': (amount/100)*investor.percentageInvestment!,
        'description':
        'Payment received from customer($customerID) for Product($productName)'
      });

    }

  }
}
