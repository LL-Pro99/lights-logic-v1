
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const LightsLogicApp());

class LightsLogicApp extends StatelessWidget {
  const LightsLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lights Logic',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101722),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD8B879),
          secondary: Color(0xFFD8B879),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();

  final rooms = [
    'Living Room',
    'Master Bedroom',
    'Kitchen',
    'Dining Room',
    'Outdoor',
  ];

  final photos = <String, String>{};
  String selectedRoom = 'Living Room';
  String selectedScene = 'Welcome';
  int tab = 0;
  bool mainLight = true;
  bool coveLight = true;
  bool curtain = false;
  bool motion = true;
  double brightness = 75;
  double curtainPosition = 100;
  double temperature = 3000;
  double acTemperature = 24;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    for (final room in rooms) {
      final path = prefs.getString(room);
      if (path != null && File(path).existsSync()) {
        photos[room] = path;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> choosePhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedRoom, image.path);

    setState(() => photos[selectedRoom] = image.path);
  }

  Future<void> resetPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(selectedRoom);
    setState(() => photos.remove(selectedRoom));
  }

  Widget roomImage(String room, {double height = 125}) {
    final path = photos[room];
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: const Color(0xFF273445),
        image: path != null && File(path).existsSync()
            ? DecorationImage(
                image: FileImage(File(path)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: path == null
          ? const Center(
              child: Icon(Icons.home_outlined,
                  size: 45, color: Color(0xFFD8B879)),
            )
          : null,
    );
  }

  Widget goldButton(String label, VoidCallback action) {
    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD8B879),
        foregroundColor: const Color(0xFF101722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }

  Widget roomCard(String room) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRoom = room;
          tab = 1;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF344253)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: roomImage(room, height: 150)),
            const SizedBox(height: 9),
            Text(room,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Smart room',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('LIGHTS LOGIC',
            style: TextStyle(
                color: Color(0xFFD8B879),
                letterSpacing: 4,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const Text('Shine your space.',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 25),
        const Text('Welcome Home',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w300)),
        const SizedBox(height: 7),
        const Text('Your home, beautifully connected.',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF354457), Color(0xFF182332)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(Icons.wifi, color: Color(0xFFD8B879), size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demo Home',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('App preview • Hub not connected',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.circle, color: Colors.orange, size: 10),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Your Rooms',
                style: TextStyle(fontSize: 20)),
            Text('${rooms.length} Rooms',
                style: const TextStyle(color: Color(0xFFD8B879))),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.12,
          children: rooms.map(roomCard).toList(),
        ),
        const SizedBox(height: 25),
        const Text('Quick Scenes', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        sceneButtons(),
      ],
    );
  }

  Widget sceneButtons() {
    final scenes = ['Welcome', 'Movie', 'Dinner', 'Night'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: scenes.map((scene) {
        final active = selectedScene == scene;
        return ChoiceChip(
          label: Text(scene),
          selected: active,
          selectedColor: const Color(0xFFD8B879),
          onSelected: (_) => setState(() {
            selectedScene = scene;
            if (scene == 'Movie') {
              brightness = 20;
              mainLight = false;
              coveLight = true;
            } else if (scene == 'Dinner') {
              brightness = 65;
              mainLight = true;
              coveLight = true;
            } else if (scene == 'Night') {
              brightness = 5;
              mainLight = false;
              coveLight = false;
            } else {
              brightness = 100;
              mainLight = true;
              coveLight = true;
            }
          }),
        );
      }).toList(),
    );
  }

  Widget controlSwitch(String label, bool value,
      ValueChanged<bool> change) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      activeColor: const Color(0xFFD8B879),
      onChanged: change,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget roomControls() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('ROOM CONTROL',
            style: TextStyle(
                color: Color(0xFFD8B879), letterSpacing: 3)),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: selectedRoom,
          decoration: const InputDecoration(
            labelText: 'Select Room',
            border: OutlineInputBorder(),
          ),
          items: rooms.map((room) {
            return DropdownMenuItem(value: room, child: Text(room));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => selectedRoom = value);
          },
        ),
        const SizedBox(height: 16),
        roomImage(selectedRoom, height: 190),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: goldButton('Choose Gallery Photo', choosePhoto)),
            const SizedBox(width: 8),
            IconButton(
              onPressed: resetPhoto,
              icon: const Icon(Icons.restore, color: Color(0xFFD8B879)),
              tooltip: 'Restore default',
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Lighting',
            style: TextStyle(fontSize: 21)),
        controlSwitch('Main Light', mainLight,
            (v) => setState(() => mainLight = v)),
        controlSwitch('Cove Lighting', coveLight,
            (v) => setState(() => coveLight = v)),
        const SizedBox(height: 10),
        Text('Brightness ${brightness.round()}%'),
        Slider(
          value: brightness,
          min: 0,
          max: 100,
          activeColor: const Color(0xFFD8B879),
          onChanged: (v) => setState(() => brightness = v),
        ),
        const Text('Colour Temperature'),
        Wrap(
          spacing: 8,
          children: [2700.0, 3000.0, 4000.0, 6500.0].map((v) {
            return ChoiceChip(
              label: Text('${v.round()}K'),
              selected: temperature == v,
              onSelected: (_) => setState(() => temperature = v),
            );
          }).toList(),
        ),
        const Divider(height: 35),
        const Text('Curtains', style: TextStyle(fontSize: 20)),
        controlSwitch('Curtain Motor', curtain,
            (v) => setState(() => curtain = v)),
        Text('Curtain Position ${curtainPosition.round()}%'),
        Slider(
          value: curtainPosition,
          min: 0,
          max: 100,
          activeColor: const Color(0xFFD8B879),
          onChanged: (v) => setState(() => curtainPosition = v),
        ),
        const Divider(height: 35),
        const Text('Climate Control', style: TextStyle(fontSize: 20)),
        Text('AC Temperature ${acTemperature.round()}°C'),
        Slider(
          value: acTemperature,
          min: 16,
          max: 30,
          divisions: 14,
          activeColor: const Color(0xFFD8B879),
          onChanged: (v) => setState(() => acTemperature = v),
        ),
      ],
    );
  }

  Widget automationPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('AUTOMATION CENTRE',
            style: TextStyle(
                color: Color(0xFFD8B879), letterSpacing: 3)),
        const SizedBox(height: 20),
        const Text('Make your home smarter',
            style: TextStyle(fontSize: 24)),
        const SizedBox(height: 15),
        controlSwitch('Motion Sensor Automation', motion,
            (v) => setState(() => motion = v)),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.hub, color: Color(0xFFD8B879)),
          title: const Text('Smart Home Hub'),
          subtitle: const Text('Not connected • Setup required'),
        ),
        ListTile(
          leading: const Icon(Icons.sensors, color: Color(0xFFD8B879)),
          title: const Text('Zigbee Network'),
          subtitle: const Text('Not connected'),
        ),
        const Divider(),
        const Text('Scenes', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        sceneButtons(),
        const SizedBox(height: 20),
        const Text(
          'Automation settings are currently a local app preview. '
          'Real sensors and hub connection will be added separately.',
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text('SETTINGS',
            style: TextStyle(
                color: Color(0xFFD8B879), letterSpacing: 3)),
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.business, color: Color(0xFFD8B879)),
          title: Text('Lights Logic'),
          subtitle: Text('Shine your space.'),
        ),
        ListTile(
          leading: Icon(Icons.photo_library, color: Color(0xFFD8B879)),
          title: Text('Room Gallery'),
          subtitle: Text('Personalise each room from your phone gallery'),
        ),
        ListTile(
          leading: Icon(Icons.security, color: Color(0xFFD8B879)),
          title: Text('Privacy'),
          subtitle: Text('Room photos saved on this device'),
        ),
        ListTile(
          leading: Icon(Icons.info_outline, color: Color(0xFFD8B879)),
          title: Text('Version 1.0.0'),
          subtitle: Text('Lights Logic Smart Home'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      roomControls(),
      automationPage(),
      settingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101722),
        title: const Text('Lights Logic',
            style: TextStyle(
                color: Color(0xFFD8B879),
                fontWeight: FontWeight.bold)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.lightbulb_outline,
                color: Color(0xFFD8B879)),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1B2838),
        indicatorColor: const Color(0xFF594B35),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.tune), label: 'Control'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome), label: 'Automation'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

