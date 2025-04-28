import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/story.dart';

class StoryPage extends StatefulWidget {
  final List<StoryOwner> storyOwners;
  final int startIndex;

  const StoryPage({
    super.key,
    required this.storyOwners,
    required this.startIndex,
  });

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  late int currentOwnerIndex;
  int currentStoryIndex = 0;
  Timer? _storyTimer;
  double _progress = 0.0;

  // Initialize currentOwnerIndex from widget.startIndex
  @override
  void initState() {
    super.initState();
    currentOwnerIndex = widget.startIndex; // Fixing the issue here
    _startStoryTimer();
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    super.dispose();
  }

  void _startStoryTimer() {
    _progress = 0.0;
    _storyTimer?.cancel();
    _storyTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    setState(() {
      if (currentStoryIndex <
          widget.storyOwners[currentOwnerIndex].stories.length - 1) {
        currentStoryIndex++;
      } else if (currentOwnerIndex < widget.storyOwners.length - 1) {
        currentOwnerIndex++;
        currentStoryIndex = 0;
      } else {
        Navigator.pop(context);
      }
      _startStoryTimer();
    });
  }

  void _previousStory() {
    setState(() {
      if (currentStoryIndex > 0) {
        currentStoryIndex--;
      } else if (currentOwnerIndex > 0) {
        currentOwnerIndex--;
        currentStoryIndex =
            widget.storyOwners[currentOwnerIndex].stories.length - 1;
      }
      _startStoryTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storyOwner = widget.storyOwners[currentOwnerIndex];
    final currentStory = storyOwner.stories[currentStoryIndex];
    final totalStories = storyOwner.stories.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: currentStory.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: storyOwner.stories.map((story) {
                            int index = storyOwner.stories.indexOf(story);
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: LinearPercentIndicator(
                                  lineHeight: 4.0,
                                  percent: index < currentStoryIndex
                                      ? 1.0
                                      : index == currentStoryIndex
                                          ? _progress
                                          : 0.0,
                                  backgroundColor: Colors.grey,
                                  progressColor: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  storyOwner.profileImage),
                              radius: 20,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              storyOwner.owner,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1.0, 1.0),
                                    blurRadius: 3.0,
                                    color: Colors.black,
                                  ),
                                ],
                                decoration: TextDecoration.none,
                                decorationColor: Colors.black,
                                decorationThickness: 2,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              DateFormat('hh:mm a').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    currentStory.date),
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1.0, 1.0),
                                    blurRadius: 3.0,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    currentStory.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      shadows: [
                        Shadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 3.0,
                          color: Colors.black,
                        ),
                      ],
                      decoration: TextDecoration.none,
                      decorationColor: Colors.black,
                      decorationThickness: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
