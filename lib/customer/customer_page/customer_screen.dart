import 'package:ecommerce_bnql/customer/customer_page/add_product.dart';
import 'package:ecommerce_bnql/customer/payment_schedule_class.dart';
import 'package:ecommerce_bnql/customer/purchase_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/viewmodel_customers.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({Key? key, required this.index}) : super(key: key);

  final int index;

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  List<PurchaseWidget> allPurchases = [];
  List<PaymentSchedule> paymentScheduleList = [];
  num outstandingBalance=0;
  num amountPaid=0;


  @override
  void initState() {
    Provider.of<CustomerView>(context, listen: false)
        .getPurchases(widget.index);
    if(Provider.of<CustomerView>(context, listen: false).monthSwitch){
      for(var customer in Provider.of<CustomerView>(context, listen: false).allCustomers[widget.index].purchases){
        outstandingBalance=outstandingBalance+customer.outstandingBalance;
        amountPaid=amountPaid+customer.amountPaid;
      }


    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              Provider.of<CustomerView>(context, listen: false)
                  .allCustomers[widget.index]
                  .name,
              style: const TextStyle(color: Colors.black, fontSize: 25),
            ),
            Expanded(child: Container()),
            CircleAvatar(
              backgroundImage: NetworkImage(
                  Provider.of<CustomerView>(context, listen: false)
                      .allCustomers[widget.index]
                      .image),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding Balance: ${Provider.of<CustomerView>(context, listen: false).allCustomers[widget.index].outstandingBalance} PKR',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Amount Paid: ${Provider.of<CustomerView>(context, listen: false).allCustomers[widget.index].paidAmount} PKR',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              children: [
                Expanded(child: Container()),
                const Text(
                  'All Purchases',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                    child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProductScreen(
                                  customerName: Provider.of<CustomerView>(
                                          context,
                                          listen: false)
                                      .allCustomers[widget.index]
                                      .name),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded)))
              ],
            ),
            const SizedBox(
              height: 10,
              child: Divider(
                thickness: 1,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: Provider.of<CustomerView>(context)
                      .allCustomers[widget.index]
                      .purchases
                      .isNotEmpty
                  ? ListView.builder(
                      physics:
                          const ScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: Provider.of<CustomerView>(context)
                          .allCustomers[widget.index]
                          .purchases
                          .length,
                      itemBuilder: (BuildContext context, int index) {
                        return PurchaseWidget(
                          image: Provider.of<CustomerView>(context)
                              .allCustomers[widget.index]
                              .purchases[index]
                              .productImage,
                          name: Provider.of<CustomerView>(context)
                              .allCustomers[widget.index]
                              .purchases[index]
                              .productName,
                          outstandingBalance: Provider.of<CustomerView>(context)
                              .allCustomers[widget.index]
                              .purchases[index]
                              .outstandingBalance,
                          amountPaid: Provider.of<CustomerView>(context)
                              .allCustomers[widget.index]
                              .purchases[index]
                              .amountPaid,
                          productIndex: index,
                          index: widget.index,
                        );
                      })
                  : Center(
                      child: CircularProgressIndicator(
                        color: Colors.teal.shade300,
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }

// void updateProfile() async {
//   String image = '';
//   String name = '';
//   int outstandingBalance;
//   int amountPaid;
//   final cloud = FirebaseFirestore.instance;
//   cloud.settings = const Settings(persistenceEnabled: true);
//
//   final purchaseCollection = await cloud
//       .collection('customers')
//       .doc(Provider.of<CustomerView>(context, listen: false)
//           .allCustomers[widget.index]
//           .documentID)
//       .collection('purchases')
//       .get();
//
//   for (var purchaseDocument in purchaseCollection.docs) {
//     final source =
//         (purchaseDocument.metadata.isFromCache) ? "local cache" : "server";
//
//     if (kDebugMode) {
//       print("Data fetched from $source}");
//     }
//     DocumentReference ref = purchaseDocument.get('product');
//     paymentScheduleList = await getPaymentSchedule(
//         purchaseDocument.reference,
//         Provider.of<CustomerView>(context, listen: false)
//             .allCustomers[widget.index]
//             .documentID);
//
//     await ref.get().then(
//       (value) async {
//         name = value.get('name');
//
//         DocumentReference vendorReference = value.get('reference');
//
//         await vendorReference.get().then((value) {
//           image = value.get('image');
//         });
//       },
//     );
//     outstandingBalance = purchaseDocument.get('outstanding_balance');
//     amountPaid = purchaseDocument.get('paid_amount');
//
//     setState(
//       () {
//         allPurchases.add(PurchaseWidget(
//           image: image,
//           name: name,
//           outstandingBalance: outstandingBalance,
//           amountPaid: amountPaid,
//         ));
//       },
//     );
//   }
// }
//
// Future<List<PaymentSchedule>> getPaymentSchedule(
//     DocumentReference reference, String customerDocID) async {
//   List<PaymentSchedule> listOfPayment = [];
//   reference
//       .collection('payment_schedule')
//       .orderBy('date', descending: false)
//       .get()
//       .then((value) {
//     for (var payment in value.docs) {
//       var amount = payment.get('amount');
//       Timestamp date = payment.get('date');
//       bool isPaid = payment.get('isPaid');
//
//       listOfPayment.add(PaymentSchedule(
//           amount: amount,
//           isPaid: isPaid,
//           date: date,
//           paymentReference: payment.id,
//           purchaseReference: reference,
//           customerdocID: customerDocID));
//     }
//   });
//   return listOfPayment;
// }
}
