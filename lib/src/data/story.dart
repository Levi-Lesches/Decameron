import "author.dart";

/// A story told by the fireplace. 
class Story {
	/// The date and time when this story was told. 
	final DateTime createdAt;

	/// The storyteller. 
	final Author author;

	/// The title of this story. 
	final String title;

	/// The first sentence of this story.
	/// 
	/// This does not necessarily have to be the first sentence spoken. Instead 
	/// it should be a catchy one-liner to hook the audience. 
	final String firstSentence;

	/// The full transcript of the story. 
	final String text;

	/// Reads a story from a JSON object. 
	Story.fromJson(Map json) : 
		createdAt = DateTime.parse(json ["createdAt"]),
		author = Author.fromJson(json ["author"]),
		title = json ["title"],
		firstSentence = json ["firstSentence"],
		text = json ["text"];
}
