import 'package:flutter/material.dart';
import '../database/model.dart';
import '../database/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProductListScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const ProductListScreen({Key? key, required this.dbHelper}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];

  // Confirm dialog for deletion
  Future<bool?> _showConfirmDialog(BuildContext context, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จองคิวแม่บ้าน'),
      ),
      body: Container(
        color: Colors.orange[100], // พื้นหลังสีส้มอ่อน
        child: Column(
          children: [
            // ส่วนของโฆษณา
            Container(
              height: 400, // ปรับความสูงของกรอบให้ใหญ่ขึ้น
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5, // จำนวนโฆษณาที่จะแสดง (เพราะมี 5 รูป)
                itemBuilder: (context, index) {
                  // สร้างเส้นทางของรูปภาพโดยใช้ชื่อไฟล์ที่ถูกต้อง
                  String imagePath = 'assets/images/maaban${index + 1}.png';

                  return Container(
                    width: 300, // ปรับความกว้างของกรอบให้ใหญ่ขึ้น
                    margin: EdgeInsets.all(16.0), // เพิ่ม margin รอบๆ กรอบ
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0), // เพิ่มความโค้งให้กรอบ
                      color: Colors.orange, // สีพื้นหลังของโฆษณา
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0), // เพิ่ม padding รอบๆ ภายในกรอบ
                      child: Column(
                        children: [
                          Expanded(
                            flex: 4, // ใช้ flex เพื่อเพิ่มพื้นที่ให้กับรูปภาพ
                            child: Image.asset(
                              imagePath, // แสดงรูปภาพจาก assets
                              fit: BoxFit.cover, // จัดการให้รูปภาพครอบคลุมพื้นที่
                            ),
                          ),
                          SizedBox(height: 10), // เพิ่มพื้นที่ระหว่างรูปภาพกับข้อความ
                          Expanded(
                            flex: 1, // พื้นที่สำหรับข้อความโฆษณา
                            child: Text(
                              'เเม่บ้านทำความสะอาดหมายเลขที่  ${index + 1}', // ข้อความโฆษณา
                              style: TextStyle(color: Colors.white, fontSize: 22), // ขนาดฟอนต์ใหญ่ขึ้น
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ส่วนของข้อมูล
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.dbHelper.getStream(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  products.clear();
                  for (var element in snapshot.data!.docs) {
                    var data = element.data() as Map<String, dynamic>;
                    products.add(Product(
                      name: element.get('name'),
                      description: element.get('description'),
                      favorite: element.get('favorite'),
                      referenceId: element.id,
                      contactnumber: data.containsKey('contactnumber')
                          ? data['contactnumber']
                          : '',
                      address: data.containsKey('address') ? data['address'] : '',
                      bookingTime: data.containsKey('bookingTime')
                          ? data['bookingTime']
                          : '',
                    ));
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: UniqueKey(),
                        background: Container(color: Colors.blue),
                        secondaryBackground: Container(
                          color: Colors.red,
                          child: const Icon(Icons.delete),
                          alignment: Alignment.centerRight,
                        ),
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            widget.dbHelper.deleteProduct(products[index]);
                            setState(() {
                              products.removeAt(index);
                            });
                          }
                        },
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            return await _showConfirmDialog(
                                context, 'แน่ใจว่าจะลบการจองนี้?');
                          }
                          return false;
                        },
                        child: Card(
                          elevation: 5,
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(products[index].name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('เลือกเเม่บ้านคนไหน: ${products[index].description}'),
                                Text('เบอร์: ${products[index].contactnumber}'),
                                Text('ที่อยู่: ${products[index].address}'),
                                Text('เวลาจอง: ${DateFormat('dd/MM/yyyy HH:mm').format(DateFormat("dd/MM/yyyy h:mm a").parse(products[index].bookingTime))}'),
                              ],
                            ),
                            onTap: () async {
                              var result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailScreen(productdetail: products[index]),
                                ),
                              );
                              setState(() {
                                if (result != null) {
                                  products[index].favorite = result;
                                  widget.dbHelper.updateProduct(products[index]);
                                }
                              });
                            },
                            onLongPress: () async {
                              await ModalEditProductForm(
                                dbHelper: widget.dbHelper,
                                editedProduct: products[index],
                              ).showModalInputForm(context);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ModalProductForm(dbHelper: widget.dbHelper)
              .showModalInputForm(context);
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({Key? key, required this.productdetail}) : super(key: key);

  final Product productdetail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productdetail.name),
        backgroundColor: Colors.orange, // เปลี่ยนสี AppBar เป็นสีส้ม
      ),
      body: Container(
        height: double.infinity, // เพิ่มให้ความสูงครอบคลุมทั้งหน้า
        decoration: BoxDecoration(
          color: Colors.orange[50], // เปลี่ยนสีพื้นหลังเป็นสีส้มจาง
        ),
        child: Padding(
          padding: const EdgeInsets.all(20), // เพิ่ม Padding รอบ ๆ
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ชื่อผู้จองเเละรายละเอียด: ${productdetail.name}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'เเม่บ้านที่เลือก: ${productdetail.description}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'ที่อยู่: ${productdetail.address}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'เบอร์โทร: ${productdetail.contactnumber}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Divider(),
                              Text(
                                'เวลาการจอง: ${productdetail.bookingTime}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(), // เพิ่มเพื่อให้ปุ่มอยู่ด้านล่าง
              Center(
                child: ElevatedButton(
                  child: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.orange,
                    fixedSize: const Size(120, 40),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ModalProductForm {
  ModalProductForm({Key? key, required this.dbHelper});
  final DatabaseHelper dbHelper;

  String _name = '', _description = '';
  String _address = '';
  String _contactnumber = '';
  final int _favorite = 0;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      _selectedTime = picked;
    }
  }

  Future<void> showModalInputForm(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFCC80), // สีพื้นหลังของโมดัลเป็นสีส้มจาง
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // ขอบมุมที่โค้งมน
          ),
          title: const Text(
            'เพิ่มการจอง',
            style: TextStyle(color: Colors.black), // ตัวอักษรเป็นสีดำ
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'ชื่อ เเละ รายละเอียด',
                      labelStyle: TextStyle(color: Colors.black), // เปลี่ยนสีข้อความเป็นดำ
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), // ขอบมุมที่โค้งมน
                        borderSide: BorderSide(color: Colors.orangeAccent, width: 2), // ขอบสีดำ
                      ),
                      filled: true, // ตั้งค่าให้มีสีพื้นหลัง
                      fillColor: Color(0xFFFFE0B2), // สีพื้นหลังของ TextField
                    ),
                    style: TextStyle(color: Colors.black), // ตัวอักษรเป็นสีดำ
                    onChanged: (value) {
                      _name = value;
                    },
                  ),
                  SizedBox(height: 10), // เพิ่มระยะห่าง
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'เลือกเเม่บ้าน',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFE0B2),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _description = value;
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'เบอร์โทร',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFE0B2),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _contactnumber = value;
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'ที่อยู่',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFE0B2),
                    ),
                    style: TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _address = value;
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _selectDate(context),
                          child: Text(
                            _selectedDate == null
                                ? 'เลือกวันที่'
                                : 'วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                            style: TextStyle(color: Colors.black), // เปลี่ยนสีข้อความเป็นดำ
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => _selectTime(context),
                          child: Text(
                            _selectedTime == null
                                ? 'เลือกเวลา'
                                : 'เวลา: ${_selectedTime!.format(context)}',
                            style: TextStyle(color: Colors.black), // เปลี่ยนสีข้อความเป็นดำ
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.black), // เปลี่ยนสีปุ่มเป็นดำ
              ),
            ),
            TextButton(
              onPressed: () {
                if (_name.isNotEmpty && _description.isNotEmpty) {
                  dbHelper.insertProduct(Product(
                    name: _name,
                    description: _description,
                    favorite: _favorite,
                    contactnumber: _contactnumber,
                    address: _address,
                    bookingTime:
                        '${DateFormat('dd/MM/yyyy').format(_selectedDate!)} ${_selectedTime!.format(context)}',
                  ));
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.black), // เปลี่ยนสีปุ่มเป็นดำ
              ),
            ),
          ],
        );
      },
    );
  }
}


class ModalEditProductForm {
  const ModalEditProductForm({Key? key, required this.dbHelper, required this.editedProduct});
  
  final DatabaseHelper dbHelper;
  final Product editedProduct;

  Future<dynamic> showModalInputForm(BuildContext context) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // เพิ่มขอบมุมที่โค้งมน
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 500,
          decoration: BoxDecoration(
            color: Color(0xFFFFCC80), // เปลี่ยนสีพื้นหลังเป็นสีส้มจาง
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)), // รักษาขอบมุมที่โค้งมนด้านบน
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconButton(
                  icon: Icon(Icons.close, color: Color.fromARGB(255, 0, 0, 0)), // เปลี่ยนสีไอคอนเป็นดำ
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Center(
                  child: Text(
                    'แก้ไขข้อมูล',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // เปลี่ยนสีตัวอักษรเป็นดำ
                    ),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await dbHelper.updateProduct(editedProduct);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'บันทึก', 
                    style: TextStyle(color: Colors.black, fontSize: 16), // เปลี่ยนสีตัวอักษรเป็นดำ
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (value) {
                        editedProduct.name = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'ชื่อเเละบริการ (เช่น ทำความสะอาด)',
                        labelText: 'ชื่อเเละรายละเอียด',
                        labelStyle: TextStyle(color: Colors.black), // เปลี่ยนสี label เป็นดำ
                        hintStyle: TextStyle(color: Colors.black54), // เปลี่ยนสี hint เป็นดำจาง
                        filled: true, // ทำให้ TextField มีพื้นหลัง
                        fillColor: Color(0xFFFFE0B2), // สีพื้นหลังของ TextField
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2), // ขอบของ TextField เป็นดำ
                          borderRadius: BorderRadius.circular(10), // ขอบมุมที่โค้งมน
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2), // ขอบเมื่อถูกเลือก
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black), // ตัวอักษรเป็นสีดำ
                    ),
                    SizedBox(height: 15), // เพิ่มระยะห่างระหว่าง TextField
                    TextField(
                      onChanged: (value) {
                        editedProduct.description = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'เลือกเเม่บ้าน (เช่น แม่บ้านคนไหน)',
                        labelText: 'เลือกเเม่บ้าน',
                        labelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Color(0xFFFFE0B2),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      onChanged: (value) {
                        editedProduct.address = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'ที่อยู่',
                        labelText: 'ที่อยู่',
                        labelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Color(0xFFFFE0B2),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      onChanged: (value) {
                        editedProduct.contactnumber = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'เบอร์โทรศัพท์',
                        labelText: 'เบอร์โทรศัพท์',
                        labelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Color(0xFFFFE0B2),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
