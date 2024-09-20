import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:task02/screen/singin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const SigninScreen(),
    );
  }
}

class TodaApp extends StatefulWidget {
  const TodaApp({super.key});

  @override
  State<TodaApp> createState() => _TodaAppState();
}

class _TodaAppState extends State<TodaApp> {
  late TextEditingController _texteditController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _texteditController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

  void addOrEditTodoHandle(BuildContext context, [DocumentSnapshot? document]) {
    if (document != null) {
      _texteditController.text = document['name'];
      _descriptionController.text = document['note'] ?? "";
    } else {
      _texteditController.clear();
      _descriptionController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document != null ? "Edit task" : "Add new task"),
          content: SizedBox(
            width: 120,
            height: 140,
            child: Column(
              children: [
                TextField(
                  controller: _texteditController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Input your task"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Description"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                CollectionReference tasks =
                    FirebaseFirestore.instance.collection("tasks");
                
                if (document != null) {
                  tasks.doc(document.id).update({
                    'name': _texteditController.text,
                    'note': _descriptionController.text,
                  }).then((res) {
                    print("Task updated");
                  }).catchError((onError) {
                    print("Failed to update task");
                  });
                } else {
                  tasks.add({
                    'name': _texteditController.text,
                    'note': _descriptionController.text,
                    'completed': false,
                  }).then((res) {
                    print("Task added");
                  }).catchError((onError) {
                    print("Failed to add new Task");
                  });
                }
                
                _texteditController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void deleteTask(DocumentSnapshot document) {
    FirebaseFirestore.instance.collection('tasks').doc(document.id).delete().then((res) {
      print("Task deleted");
    }).catchError((onError) {
      print("Failed to delete task");
    });
  }

  void toggleTaskCompletion(DocumentSnapshot document) {
    FirebaseFirestore.instance.collection('tasks').doc(document.id).update({
      'completed': !(document['completed'] as bool),
    }).then((res) {
      print("Task status updated");
    }).catchError((onError) {
      print("Failed to update task status");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context), // Logout button
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("tasks").snapshots(),
        builder: (context, snapshot) {
          return snapshot.data != null
              ? ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = snapshot.data!.docs[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: document['completed'],
                            onChanged: (value) {
                              toggleTaskCompletion(document);
                            },
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document['name'],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    decoration: document['completed']
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                if (document['note'] != null &&
                                    document['note'] != "")
                                  Text(document['note']),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              addOrEditTodoHandle(context, document);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              deleteTask(document);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const Text("No data");
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addOrEditTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
