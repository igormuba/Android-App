import 'dart:convert';
import 'dart:developer';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/login/login_bridge_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_details_model/video_details.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({Key? key}) : super(key: key);

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  Future<List<VideoDetails>>? loadVideos;
  Future<void>? loadOperations;
  var isLoading = false;

  void logout() async {
    // Create storage
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'username');
    await storage.delete(key: 'postingKey');
    server.updateHiveUserData(null);
    Navigator.of(context).pop();
  }

  void loadVideoInfo(HiveUserData user, String videoId) async {
    setState(() {
      isLoading = true;
    });
    try {
      var result = await Communicator().loadOperations(user, videoId);
      var utf8data = utf8.encode(result);
      final base64Str = base64.encode(utf8data);
      var platform = MethodChannel('com.example.acela/auth');
      final String response = await platform.invokeMethod('postVideo', {
        'data': base64Str,
        'postingKey': user.postingKey,
      });
      var bridgeResponse = LoginBridgeResponse.fromJsonString(response);
      if (bridgeResponse.valid == true) {
        await Communicator().updatePublishState(user, videoId);
        setState(() {
          loadVideos = Communicator().loadVideos(user);
        });
      } else {
        showError('Error occurred: ${bridgeResponse.error}');
      }
      log('Result from android platform is \n$response');
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showError('Error occurred - ${e.toString()}');
    }
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  AppBar _appBar(String username) {
    return AppBar(
      title: Row(
        children: [
          CustomCircleAvatar(
            height: 36,
            width: 36,
            url: 'https://images.hive.blog/u/$username/avatar',
          ),
          const SizedBox(width: 5),
          Text(username),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            logout();
          },
          icon: Icon(Icons.exit_to_app),
        )
      ],
    );
  }

  Widget _trailingActionOnVideoListItem(VideoDetails item, HiveUserData user) {
    return item.status == 'published'
        ? Icon(Icons.check, color: Colors.green)
        : item.status == 'publish_manual'
            ? IconButton(
                onPressed: () {
                  loadVideoInfo(user, item.id);
                },
                icon: Icon(
                  Icons.rocket_launch,
                  color: Colors.green,
                ),
              )
            : Icon(
                Icons.hourglass_top,
                color: Colors.blue,
              );
  }

  Widget _videoListItem(VideoDetails item, HiveUserData user) {
    return ListTile(
      leading: Image.network(
        item.thumbUrl,
      ),
      title: Text(item.title),
      subtitle: Text(item.description.length > 30
          ? item.description.substring(0, 30)
          : item.description),
      trailing: _trailingActionOnVideoListItem(item, user),
      onTap: () {},
    );
  }

  Widget _videosList(List<VideoDetails> items, HiveUserData user) {
    return ListView.separated(
      itemBuilder: (context, index) {
        return _videoListItem(items[index], user);
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: items.length,
    );
  }

  Widget _videoFuture(HiveUserData user) {
    return FutureBuilder(
      future: loadVideos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: const Text('Something went wrong'));
        } else if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return _videosList(snapshot.data as List<VideoDetails>, user);
        } else {
          return const LoadingScreen();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<HiveUserData?>(context);
    if (user != null && loadVideos == null) {
      setState(() {
        loadVideos = Communicator().loadVideos(user);
      });
    }
    var username = user?.username ?? 'Unknown';
    return Scaffold(
      appBar: _appBar(username),
      body: Container(
        child: user == null
            ? Center(child: const Text('Nothing'))
            : isLoading
                ? Center(child: const CircularProgressIndicator())
                : _videoFuture(user),
      ),
    );
  }
}
