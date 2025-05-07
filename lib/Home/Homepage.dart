import 'package:flutter/material.dart';
import '../Founditems/Found.dart';
import '../LostItems/Lost.dart';
import 'Home.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int selectedindex = 0;
  static List<Widget> widgetoptions = <Widget>[
    const Home(),
    const Lost(),
    const Found(),
    //const Profile(),
  ];

  void onitemtap(int index) {
    setState(() {
      selectedindex = index;
    });
  }

  // Function to navigate to chat page
  // void _navigateToChat(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const ChatListPage()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widgetoptions.elementAt(selectedindex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.find_replace),
            label: "Lost",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.find_in_page),
            label: "Found",
          ),
        ],
        currentIndex: selectedindex,
        selectedItemColor: Colors.grey.shade900,
        iconSize: 20,
        onTap: onitemtap,
        elevation: 5,
      ),
      // Add floating action button here
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _navigateToChat(context),
      //   backgroundColor: Colors.blue,
      //   child: const Icon(Icons.chat, color: Colors.white),
      // ),
      // Position the FAB at the bottom right (default)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}