import "dart:typed_data";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:decameron/models.dart";

/// A widget that puts a [TextFormField] next to a [Text] label. 
class FormRow extends StatelessWidget {
	/// The label to show. 
	final String label;

	/// A smaller hint under the label. 
	final String subtitle;

	/// A callback for when [FormState.save] is called. 
	final void Function(String) onSaved;

	/// A function to validate the entered string.
	final FormFieldValidator<String> validator;

	/// Puts a textbox next to a label.
	const FormRow({
		@required this.onSaved,
		@required this.label,
		this.subtitle,
		this.validator,
	});

	@override
	Widget build(BuildContext context) => Padding(
		padding: const EdgeInsets.symmetric(vertical: 10), 
		child: Row(
			children: [
				Expanded(
					flex: 1, 
					child: ListTile(
						title: Text(label),
						subtitle: Text(subtitle ?? ""),
					)
				),
				Expanded(
					flex: 2,
					child: TextFormField(onSaved: onSaved, validator: validator)
				),
			]
		)
	);
}

enum VideoState {read, upload}

/// A page to create and upload a new story. 
class StoryUploaderPage extends StatefulWidget {
	@override
	StoryUploaderState createState() => StoryUploaderState();
}

/// A state to manage all the individual fields of [StoryUploaderPage]. 
class StoryUploaderState extends State<StoryUploaderPage> {
	static const int bytesPerRead = 1000000;
	
	/// The model that builds the story field by field. 
	StoryBuilderModel model = StoryBuilderModel();
	final FilePicker filePicker = FilePicker.platform;

	/// If the page is loading. 
	bool isLoading = false;
	double videoProgress;
	VideoState videoState;

	@override
	Widget build(BuildContext context) => Scaffold(
		appBar: AppBar(title: const Text("Tell a story")),
		floatingActionButton: !isLoading ? null : FloatingActionButton(
			onPressed: null,
			child: CircularProgressIndicator(
				valueColor: AlwaysStoppedAnimation(  // has to be an animation
					Theme.of(context).colorScheme.onSecondary
				)
			),
		),
		body: Form(
			child: Center(child: 
				ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 750),
					child: ListView(
						padding: const EdgeInsets.all(10),
						children: [
							const SizedBox(height: 10),
							FractionallySizedBox( 
								widthFactor: 2/3,
								child: TextFormField(
									onSaved: (String value) => model.title = value,
									textAlign: TextAlign.center, 
									decoration: const InputDecoration(
										hintText: "Your amazing story",
										border: OutlineInputBorder(),
									),
								)
							),
							const SizedBox(height: 20),
							const AspectRatio(
								aspectRatio: 1.5,
								child: Placeholder()
							),
							if (videoProgress != null) ...[
								LinearProgressIndicator(value: videoProgress),
								if (videoState == VideoState.read)
									const Text("Reading video")
								else if (videoState == VideoState.upload)
									const Text("Uploading video")
							],
							const SizedBox(height: 10),
							Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
									const Text("Upload a video"),
									OutlinedButton(
										child: const Text("Select file"),
										onPressed: selectFile,
									)
								]
							),
							const SizedBox(height: 30),
							FormRow(
								label: "Catchy first sentence",
								onSaved: (String value) => model.firstSentence = value,
							),
							const SizedBox(height: 20),
							const Text("Type out the full story here"),
							const SizedBox(height: 10),
							TextFormField(
								onSaved: (String value) => model.text = value,
								maxLines: null,
								decoration: const InputDecoration(
									filled: true,
									border: OutlineInputBorder()
								),
							),
							const SizedBox(height: 20),
							Builder(
								builder: (BuildContext context) => SizedBox(
									width: 100, child: RaisedButton(
										onPressed: () => upload(context),
										child: const Text("Upload"),
									)
								)
							)
						]
					)
				)
			)
		)
	);

	Future<void> selectFile() async {
		final FilePickerResult result = await filePicker.pickFiles(
			type: FileType.video, 
			withReadStream: true,
		);
		if (result == null) {
			return;
		}
		model.video = await readVideo(result.files.first);
	}

	Future<Uint8List> readVideo(PlatformFile file) async {
		final int totalReads = file.size ~/ bytesPerRead;
		int currentRead = 0;
		final Uint8List bytes = Uint8List(file.size);
		int index = 0;
		videoState = VideoState.read;
		await for (final List<int> newBytes in file.readStream) {
			bytes.setRange(index, index + newBytes.length, newBytes);
			index += newBytes.length;
			setState(() {
				videoProgress = currentRead++ / totalReads;
				if (videoProgress == 1) {  // done reading
					videoProgress = null;
					model.video = bytes;
				}
			});
		}
		return bytes;
	}

	/// Uploads the story inputted by the user. 
	Future<void> upload(BuildContext context) async {
		setState(() => isLoading = true);
		try {
			if (!Form.of(context).validate()) {
				setState(() => isLoading = false);
				return;
			}
			Form.of(context).save();
			await Models.instance.stories.upload(model.story);
		} catch (error) {  // ignore: avoid_catches_without_on_clauses
			Scaffold.of(context).showSnackBar(
				SnackBar(
					content: const Text("Error while uploading story"),
					action: SnackBarAction(
						label: "RETRY",
						onPressed: () => upload(context),
					)
				)
			);
			setState(() => isLoading = false);
			rethrow;
		}
		setState(() => isLoading = false);
		Navigator.of(context).pop();
	}
}
