import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:innopolis_feedback/screens/addCourse.dart';
import 'package:innopolis_feedback/screens/editCourse.dart';
import 'package:innopolis_feedback/screens/addTA.dart';
import 'package:innopolis_feedback/screens/editTA.dart';
import 'package:innopolis_feedback/screens/wrapper.dart';
import 'package:innopolis_feedback/services/auth.dart';
import 'package:innopolis_feedback/shared/FloatingActionButtonMenu.dart';
import 'package:innopolis_feedback/shared/loading.dart';
import 'package:innopolis_feedback/shared/styles.dart';
import 'package:provider/provider.dart';

import 'ta_course_page.dart';

import 'data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<User>.value(
      value: AuthService().user,
      child: MaterialApp(
        home: Wrapper(),
        title: 'Innopolis Feedback',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AuthService _auth = AuthService();
  bool isAdmin = false;

  List<Year> years;
  Year selectedYear;
  Course selectedCourse;
  TA selectedTA;

  List currentList;
  Function currentBuilder;

  goBack() async {
    if (selectedCourse != null) {
      await selectYear(selectedYear);
      return setState(() {
        selectedCourse = null;
      });
    }
    if (selectedYear != null) {
      return setState(() {
        selectedYear = null;
      });
    }
  }

  selectYear(Year year) async {
    print('Selected year: ' + year.name);
    List<Course> temp = await getCoursesByYear(year);
    setState(() {
      currentList = temp;
      selectedYear = year;
      currentBuilder = courseItemBuilder;
    });
  }

  selectCourse(Course course) async {
    print('Selected course: ' + course.name);

    List<TA> temp = await getTAs(course);
    setState(() {
      currentList = temp;
      selectedCourse = course;
      currentBuilder = taItemBuilder;
    });
  }

  selectTA(TA ta) {
    print('Selected TA: ' + ta.name);
    String title = ta.name + ' - ' + selectedCourse.name;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                TaCoursePage(title, ta.id, selectedCourse.id)));
  }

  Widget yearItemBuilder(Year year) {
    return ListTile(
      title: Text(year.name),
      onTap: () async => await selectYear(year),
    );
  }

  Widget courseItemBuilder(Course course) {
    if (isAdmin) {
      return Builder(
        builder: (context) => ListTile(
          title: Text(course.name),
          onTap: () => selectCourse(course),
          trailing: trailingPopupMenu(course, "Course", course.name, () async {
            await deleteCourse(course.id);
          }, () async {
            await selectYear(selectedYear);
          }, () async {
            final result = tryCast<bool>(
                await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditCourse(course))) ??
                    false,
                fallback: false);
            if (result) {
              showSuccessSnackBar(context, "Course successfully edited!");
            }
            if (selectedCourse != null) {
              await selectCourse(selectedCourse);
            }
          }),
        ),
      );
    } else {
      return ListTile(
          title: Text(course.name),
          onTap: () async => await selectCourse(course));
    }
  }

  Widget taItemBuilder(TA ta) {
    if (isAdmin) {
      return Builder(
        builder: (context) =>
            ListTile(
                title: Text(ta.name),
                onTap: () => selectTA(ta),
                trailing: trailingPopupMenu(ta, "TA", ta.name, () async {
                  await deleteTA(ta.id);
                }, () async {
                  await selectCourse(selectedCourse);
                }, () async {
                  final result = tryCast<bool>(
                      await Navigator.push(context,
                          MaterialPageRoute(
                              builder: (context) => EditTA(ta))) ??
                          false,
                      fallback: false);
                  if (result) {
                    showSuccessSnackBar(context, "TA successfully edited!");
                  }
                  if (selectedCourse != null) {
                    await selectCourse(selectedCourse);
                  }
                })
            ),
      );
    } else {
      return ListTile(
        title: Text(ta.name),
        onTap: () => selectTA(ta),
      );
    }
  }

  Widget trailingPopupMenu(dynamic selectedItem, String itemType,
      String representation, Function delete, Function update, Function edit) {
    return Builder(
      builder: (context) {
        return PopupMenuButton(
            icon: Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case "remove":
                  try {
                    await delete();
                    showSuccessSnackBar(context,
                        "$itemType '$representation' successfully deleted!");
                  } catch (e) {
                    print(e.toString());
                    if (e.toString().contains("] ")) {
                      showErrorSnackBar(
                          context,
                          "Unable to delete $itemType \'" +
                              selectedItem.id +
                              "\'.",
                          e.toString().split("] ")[1]);
                    } else {
                      showErrorSnackBar(
                          context,
                          "Unable to delete $itemType \'" +
                              selectedItem.id +
                              "\'.",
                          e.toString());
                    }
                  }
                  await update();
                  break;
                case "edit":
                  try {
                    await edit();
                  } catch (e) {
                    print(e.toString());
                    if (e.toString().contains("] ")) {
                      showErrorSnackBar(
                          context,
                          "Unable to edit $itemType \'" +
                              selectedItem.id +
                              "\'.",
                          e.toString().split("] ")[1]);
                    } else {
                      showErrorSnackBar(
                          context,
                          "Unable to edit $itemType \'" +
                              selectedItem.id +
                              "\'.",
                          e.toString());
                    }
                  }
                  await update();
                  break;
              }
            },
            itemBuilder: (context) => [
                  PopupMenuItem(
                      value: "remove",
                      child: Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
                            child: Icon(Icons.delete),
                          ),
                          Text('Delete')
                        ],
                      )),
              PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
                        child: Icon(Icons.edit),
                      ),
                      Text('Edit')
                    ],
                  )),
            ]);
      },
    );
  }

  Widget floatingActionButtonMenu(BuildContext context) =>
      FloatingActionButtonMenu(
        tooltip: "Add",
        animatedIcon: AnimatedIcons.menu_close,
        menuItems: [
          FloatingActionButton(
            heroTag: 'add_ta',
            onPressed: () async {
              final result = tryCast<bool>(
                  await Navigator.push(context,
                          MaterialPageRoute(builder: (context) => AddTA())) ??
                      false,
                  fallback: false);
              if (result) {
                showSuccessSnackBar(context, "TA successfully added!");
              }
              if (selectedCourse != null) {
                await selectCourse(selectedCourse);
              }
            },
            tooltip: 'Add TA',
            backgroundColor: ColorsStyle.primary,
            child: Icon(Icons.person_add),
          ),
          FloatingActionButton(
              heroTag: 'add_course',
              onPressed: () async {
                final result = tryCast<bool>(
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddCourse())) ??
                        false,
                    fallback: false);
                if (result) {
                  showSuccessSnackBar(context, "Course successfully added!");
                }
                if (selectedYear != null) {
                  await selectYear(selectedYear);
                }
              },
              tooltip: 'Add Course',
              backgroundColor: ColorsStyle.primary,
              child: Icon(Icons.post_add)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        goBack();
        return false;
      },
      child: Scaffold(
          floatingActionButton: FutureBuilder<Student>(
            future: getStudentById(_auth.getCurrentUserId()),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.isAdmin()) {
                  isAdmin = true;
                  return floatingActionButtonMenu(context);
                } else {
                  return Container();
                }
              }
              if (snapshot.hasError) {
                print(snapshot.error);
                return Container();
              }
              return Loading();
            },
          ),
          appBar: AppBar(
            title: Text('Innopolis Feedback'),
            actions: <Widget>[
              FlatButton.icon(
                icon: Icon(Icons.person),
                label: Text('Sign out?'),
                onPressed: () => AuthService().signOut(),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text('Welcome to Innopolis Feedback!',
                    style: TextStyle(fontSize: 22)),
              ),
              Expanded(
                child: FutureBuilder(
                  future: getYears(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      years = snapshot.data;
                      if (selectedYear == null) {
                        currentList = years;
                        currentBuilder = yearItemBuilder;
                      }
                      return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) =>
                              currentBuilder(currentList[index]));
                    }
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Text('Oops! Something went wrong :(');
                    }
                    return Loading();
                  },
                ),
              ),
              if (selectedYear != null || selectedCourse != null)
                RaisedButton(
                  child: Text('Back'),
                  onPressed: goBack,
                )
            ],
          )),
    );
  }
}

T tryCast<T>(dynamic x, {T fallback}) {
  try {
    return (x as T);
  } on TypeError catch (e) {
    print('CastError when trying to cast $x to $T! \n($e)');
    return fallback;
  }
}

void showSuccessSnackBar(BuildContext context, String message) {
  Scaffold.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
        SnackBar(backgroundColor: ColorsStyle.success, content: Text(message)));
}

void showErrorSnackBar(BuildContext context, String message, String error) {
  Scaffold.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(
        duration: Duration(seconds: 6),
        backgroundColor: ColorsStyle.error,
        content: RichText(
          text: TextSpan(text: message, children: <TextSpan>[
            TextSpan(text: '\nReason: '),
            TextSpan(text: error, style: TextStyle(fontWeight: FontWeight.bold))
          ]),
        )));
}
