import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'data.dart';

class FeedbackForm extends StatefulWidget {
  final TaCourse taCourse;

  FeedbackForm(this.taCourse);

  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  TextEditingController controller = new TextEditingController();
  String uid, email;
  bool isAnonymous = false;

  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser.uid;
    email = FirebaseAuth.instance.currentUser.email;
  }

  handleSubmitFeedback() {
    // TODO: show a confirmation message (ex: Are you sure?)
    StudentFeedback f = new StudentFeedback('', widget.taCourse.taId,
        widget.taCourse.courseId, controller.text, uid, email, [], []);
    submitFeedback(f, isAnonymous);
    controller.text = '';
    setState(() {
      isAnonymous = false;
    });
    // TODO: display a notification (snackbar) to show that feedback was sent
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
                hintText: 'Your feedback message', labelText: 'Feedback'),
          ),
          SwitchListTile(
            title: Text('Anonymous feedback'),
            value: isAnonymous,
            onChanged: (value) {
              setState(() {
                isAnonymous = value;
              });
            },
          ),
          RaisedButton(
            child: Text('Submit Feedback'),
            onPressed: handleSubmitFeedback,
          )
        ],
      ),
    );
  }
}

class FeedbackDisplay extends StatefulWidget {
  final TaCourse taCourse;

  FeedbackDisplay(this.taCourse);

  @override
  _FeedbackDisplayState createState() => _FeedbackDisplayState();
}

class _FeedbackDisplayState extends State<FeedbackDisplay> {
  List<StudentFeedback> feedbackList = [];
  String uid, email;

  updateFeedback(List<StudentFeedback> f) {
    setState(() {
      feedbackList = f;
    });
  }

  fetchFeedback() {
    getFeedback(widget.taCourse).listen((f) {
      updateFeedback(f);
    });
  }

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser.uid;
    email = FirebaseAuth.instance.currentUser.email;
    fetchFeedback();
  }

  handleUpvote(StudentFeedback f) {
    // toggle the upvote state
    if (f.upvotes.contains(email))
      f.upvotes.remove(email);
    else
      f.upvotes.add(email);
    // make sure that there is no downvote at the same time
    f.downvotes.remove(email);
    return updateVotes(f);
  }

  handleDownvote(StudentFeedback f) {
    // toggle the downvote state
    if (f.downvotes.contains(email))
      f.downvotes.remove(email);
    else
      f.downvotes.add(email);
    // make sure that there is no upvote at the same time
    f.upvotes.remove(email);
    return updateVotes(f);
  }

  handleFeedbackLongPress(StudentFeedback f) async {
    bool shouldDelete = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete feedback'),
              content: Text('Are you sure you want to delete this feedback?'),
              actions: [
                TextButton(
                  child: Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldDelete) deleteFeedback(f);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          var f = feedbackList[index];
          bool upvoted = f.upvotes.contains(email);
          bool downvoted = f.downvotes.contains(email);
          return ListTile(
            title: Text(f.email),
            subtitle: Text(f.message),
            onLongPress: uid == f.uid ? () => handleFeedbackLongPress(f) : null,
            leading: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: upvoted ? Colors.yellow : null),
              constraints: BoxConstraints(maxWidth: 72),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(f.upvotes.length.toString()),
                IconButton(
                  icon: Icon(Icons.arrow_upward),
                  onPressed: () => handleUpvote(f),
                )
              ]),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: downvoted ? Colors.red[200] : null),
              constraints: BoxConstraints(maxWidth: 72),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(f.downvotes.length.toString()),
                  IconButton(
                    icon: Icon(Icons.arrow_downward),
                    onPressed: () => handleDownvote(f),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
