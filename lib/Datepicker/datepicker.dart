import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerScreen extends StatefulWidget {
  const DatePickerScreen({Key? key}) : super(key: key);

  @override
  State<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  final TextEditingController dateController = TextEditingController();
  TimeOfDay selectedTime = TimeOfDay(hour: 2, minute: 30);

  @override
  void initState() {
    super.initState();
    dateController.text = ''; // Initialize the text field
  }

  // Function to show time picker
  void showTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Date & Time Picker"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Date Picker Field
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: "Select Date",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200),
                  );

                  if (pickedDate != null) {
                    String formattedDate =
                    DateFormat("yyyy - MM - dd").format(pickedDate);
                    setState(() {
                      dateController.text = formattedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Time Picker Button
              ElevatedButton(
                onPressed: showTime,
                child: const Text("Set Time"),
              ),

              const SizedBox(height: 20),

              // Display Selected Time
              Text(
                "Selected Time: ${selectedTime.format(context)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
