import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// --- CAMBIA TU IP AQUÍ ---
const String URL = kIsWeb
    ? 'http://127.0.0.1:8000'
    : 'http://192.168.1.XX:8000';

void main() => runApp(const AppLogiTrack());

class AppLogiTrack extends StatelessWidget {
  const AppLogiTrack({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogiTrack',
      // TEMA: Morado (DeepPurple) y fondo gris muy claro
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Gris muy clarito
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      home: const Login(),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _usr = TextEditingController();
  final _pwd = TextEditingController();

  Future<void> _entrar() async {
    try {
      final res = await http.post(
        Uri.parse('$URL/autenticar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"usuario": _usr.text, "clave": _pwd.text}),
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Menu(id: d['id'], nom: d['nombre']),
          ),
        );
      } else {
        _aviso("Usuario no encontrado");
      }
    } catch (e) {
      _aviso("Sin conexión");
    }
  }

  void _aviso(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Logo simple
              const Icon(Icons.alt_route, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 10),
              const Text(
                "Acceso Conductores",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 30),

              // DIFERENCIA CLAVE: Tarjeta contenedora (Card)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usr,
                        decoration: const InputDecoration(
                          labelText: "Usuario",
                          icon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _pwd,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Contraseña",
                          icon: Icon(Icons.vpn_key),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _entrar,
                          child: const Text("INGRESAR"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Menu extends StatefulWidget {
  final int id;
  final String nom;
  const Menu({super.key, required this.id, required this.nom});
  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  List _data = [];
  @override
  void initState() {
    super.initState();
    _get();
  }

  Future<void> _get() async {
    final r = await http.get(Uri.parse('$URL/mi-ruta/${widget.id}'));
    if (r.statusCode == 200) setState(() => _data = jsonDecode(r.body));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Envíos")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            alignment: Alignment.centerLeft,
            child: Text(
              "Bienvenido, ${widget.nom}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _data.length,
              itemBuilder: (c, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    // DIFERENCIA: Icono circular
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _data[i]['direccion_destino'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("ID: ${_data[i]['id']}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => Detalle(d: _data[i])),
                  ).then((_) => _get()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Detalle extends StatefulWidget {
  final dynamic d;
  const Detalle({super.key, required this.d});
  @override
  State<Detalle> createState() => _DetalleState();
}

class _DetalleState extends State<Detalle> {
  Uint8List? _imgBytes;
  String? _pathMovil;
  String? _gps;
  bool _load = false;

  Future<void> _mapa() async => launchUrl(
    Uri.parse(
      "http://maps.google.com/?q=${widget.d['latitud']},${widget.d['longitud']}",
    ),
    mode: LaunchMode.externalApplication,
  );

  Future<void> _fotoGPS() async {
    try {
      Position p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _gps = "${p.latitude}, ${p.longitude}");
    } catch (e) {
      setState(() => _gps = "No GPS");
    }

    final xfile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
    );
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      setState(() {
        _imgBytes = bytes;
        _pathMovil = xfile.path;
      });
    }
  }

  Future<void> _fin() async {
    if (_imgBytes == null || _gps == null) return;
    setState(() => _load = true);
    var req = http.MultipartRequest('POST', Uri.parse('$URL/terminar'));
    req.fields['id_envio'] = widget.d['id'].toString();
    req.fields['gps'] = _gps!;

    if (kIsWeb) {
      req.files.add(
        http.MultipartFile.fromBytes('foto', _imgBytes!, filename: 'web.jpg'),
      );
    } else {
      req.files.add(await http.MultipartFile.fromPath('foto', _pathMovil!));
    }

    if ((await req.send()).statusCode == 200) Navigator.pop(context);
    setState(() => _load = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Entrega")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(
              widget.d['direccion_destino'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            OutlinedButton(onPressed: _mapa, child: const Text("Ver en Mapa")),
            const SizedBox(height: 20),

            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: _imgBytes == null
                  ? const Center(
                      child: Text(
                        "Sin evidencia",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_imgBytes!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 10),
            if (_gps != null)
              Text(
                "GPS Capturado: $_gps",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fotoGPS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                    child: const Text("CÁMARA"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_imgBytes != null && !_load) ? _fin : null,
                    child: _load
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("ENVIAR"),
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
