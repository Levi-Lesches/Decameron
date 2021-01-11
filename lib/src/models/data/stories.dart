import "package:decameron/data.dart";
import "package:decameron/services.dart";

import "model.dart";

/// The data models for the stories. 
/// 
/// All logic pertaining to getting and setting stories happens here. 
class Stories extends Model {
	/// The first twenty random stories.
	List<Story> randomStories;

	/// Downloads random stories from the database. 
	/// 
	/// See [Database.getRandomStories].
	Future<List<Story>> getRandomStories() async {
		final Iterable<Map> randomJson = 
			await Services.instance.database.getRandomStories(10);

		return [
			for (final Map<String, dynamic> json in randomJson)
				Story.fromJson(json)
		];
	}

	@override
	Future<void> init() async {
		randomStories = await getRandomStories();
	}

	/// Uploads a story to the database. 
	/// 
	/// Also updates the random list of stories.
	Future<void> upload(Story story, String id) async { 
		await Services.instance.database.uploadStory(story.json, id);
		randomStories = await getRandomStories();
		notifyListeners();  // updates the fireplace with the new story
	}
}