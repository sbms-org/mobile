import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../data/servicebook_api.dart';
import '../domain/models/servicebook_models.dart';

String _text(BuildContext context, String english, String amharic) =>
    Localizations.localeOf(context).languageCode == 'am' ? amharic : english;

String _roleName(BuildContext context, UserRole role) => switch (role) {
  UserRole.client => _text(context, 'Client', 'ደንበኛ'),
  UserRole.individualProvider => _text(
    context,
    'Individual provider',
    'ግለሰብ አገልግሎት ሰጪ',
  ),
  UserRole.companyStaff => _text(context, 'Company staff', 'የድርጅት ሰራተኛ'),
  UserRole.broker => _text(context, 'Broker', 'ደላላ'),
  UserRole.supportAgent => _text(context, 'Support agent', 'የድጋፍ ሰራተኛ'),
  UserRole.admin => _text(context, 'Admin', 'አስተዳዳሪ'),
};

class ServiceBookHomePage extends ConsumerStatefulWidget {
  const ServiceBookHomePage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<ServiceBookHomePage> createState() =>
      _ServiceBookHomePageState();
}

class _ServiceBookHomePageState extends ConsumerState<ServiceBookHomePage> {
  int _index = 0;

  bool get _isProvider =>
      widget.role == UserRole.individualProvider ||
      widget.role == UserRole.companyStaff;

  List<String> get _labels => _isProvider
      ? [
          _text(context, 'My services', 'አገልግሎቶቼ'),
          _text(context, 'Work feed', 'የስራ ማስታወቂያዎች'),
          _text(context, 'Bookings', 'ቦታ ማስያዣዎች'),
          _text(context, 'Safety', 'ደህንነት'),
        ]
      : widget.role == UserRole.client
      ? [
          _text(context, 'Nearby', 'በአቅራቢያ'),
          _text(context, 'Work feed', 'የስራ ማስታወቂያዎች'),
          _text(context, 'Bookings', 'ቦታ ማስያዣዎች'),
          _text(context, 'Safety', 'ደህንነት'),
        ]
      : [
          _text(context, 'Overview', 'አጠቃላይ'),
          _text(context, 'Work feed', 'የስራ ማስታወቂያዎች'),
          _text(context, 'Bookings', 'ቦታ ማስያዣዎች'),
          _text(context, 'Safety', 'ደህንነት'),
        ];

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_index == 0 && widget.role == UserRole.client) {
      body = const NearbyProvidersPage();
    } else if (_index == 0 && _isProvider) {
      body = const MyServicesPage();
    } else if (_index == 0) {
      body = StaffOverviewPage(role: widget.role);
    } else if (_index == 1) {
      body = WorkFeedPage(canCreatePost: _isProvider);
    } else if (_index == 2) {
      body = BookingsPage(canManage: _isProvider);
    } else {
      body = const SafetyPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceBook'),
        actions: [
          IconButton(
            tooltip: _text(context, 'Change language', 'ቋንቋ ቀይር'),
            onPressed: () {
              final current = Localizations.localeOf(context).languageCode;
              ref
                  .read(localeProvider.notifier)
                  .setLocale(Locale(current == 'en' ? 'am' : 'en'));
            },
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _roleName(context, widget.role),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: ApiClient.demoMode,
            builder: (context, demoMode, _) => demoMode
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DF),
                      border: Border.all(color: const Color(0xFFE6D49B)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _text(
                        context,
                        'Demo data is active. Changes are simulated and are not saved to the live database.',
                        'የሙከራ ውሂብ ንቁ ነው። ለውጦች በማስመሰል ላይ ብቻ ናቸው እና በቀጥታ ዳታቤዝ አይቀመጡም።',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(switch (i) {
                0 =>
                  widget.role == UserRole.client
                      ? Icons.location_searching
                      : Icons.home_repair_service_outlined,
                1 => Icons.dynamic_feed_outlined,
                2 => Icons.event_note_outlined,
                _ => Icons.shield_outlined,
              }),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}

class NearbyProvidersPage extends StatefulWidget {
  const NearbyProvidersPage({super.key});

  @override
  State<NearbyProvidersPage> createState() => _NearbyProvidersPageState();
}

class _NearbyProvidersPageState extends State<NearbyProvidersPage> {
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _radius = TextEditingController(text: '10');
  final _category = TextEditingController();
  String _meetingMode = 'provider_comes';
  bool _loading = false;
  String? _error;
  List<ServiceProvider>? _providers;

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _radius.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final latitude = double.tryParse(_latitude.text.trim());
    final longitude = double.tryParse(_longitude.text.trim());
    final radius = double.tryParse(_radius.text.trim());
    if (latitude == null ||
        longitude == null ||
        radius == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        radius <= 0) {
      setState(
        () => _error = _text(
          context,
          'Enter valid latitude, longitude and radius.',
          'ትክክለኛ ኬክሮስ፣ ኬንትሮስ እና ራዲየስ ያስገቡ።',
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _providers = null;
    });
    try {
      final result = await ServiceBookApi.nearbyProviders(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radius,
        category: _category.text.trim(),
        meetingMode: _meetingMode,
      );
      if (mounted) setState(() => _providers = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        _text(context, 'Find services near you', 'በአቅራቢያዎ አገልግሎቶችን ያግኙ'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        _text(
          context,
          'Use your location coordinates to search. Location is only sent when you submit.',
          'ለመፈለግ የቦታ መጋጠሚያዎችን ያስገቡ። ቦታው ሲፈልጉ ብቻ ይላካል።',
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _field(
              _latitude,
              _text(context, 'Latitude', 'ኬክሮስ'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              _longitude,
              _text(context, 'Longitude', 'ኬንትሮስ'),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _field(
              _radius,
              _text(context, 'Radius (km)', 'ርቀት (ኪ.ሜ)'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              _category,
              _text(context, 'Category (optional)', 'ምድብ (አማራጭ)'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _meetingMode,
        decoration: InputDecoration(
          labelText: _text(context, 'Meeting mode', 'የስብሰባ አይነት'),
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: 'provider_comes',
            child: Text(
              _text(context, 'Provider comes to me', 'አገልግሎት ሰጪው ወደ እኔ ይመጣል'),
            ),
          ),
          DropdownMenuItem(
            value: 'client_goes',
            child: Text(
              _text(context, 'I go to the provider', 'ወደ አገልግሎት ሰጪው እሄዳለሁ'),
            ),
          ),
          DropdownMenuItem(
            value: 'third_location',
            child: Text(
              _text(context, 'Meet at a third location', 'በሌላ ቦታ እንገናኛለን'),
            ),
          ),
        ],
        onChanged: (value) =>
            setState(() => _meetingMode = value ?? 'provider_comes'),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _loading ? null : _search,
        icon: const Icon(Icons.search),
        label: Text(_text(context, 'Search nearby', 'በአቅራቢያ ፈልግ')),
      ),
      if (_loading) const _LoadingState(),
      if (_error != null) _ErrorState(message: _error!, onRetry: _search),
      if (_providers != null && _providers!.isEmpty)
        _EmptyState(
          message: _text(
            context,
            'No providers found for this search.',
            'ለዚህ ፍለጋ አገልግሎት ሰጪ አልተገኘም።',
          ),
        ),
      if (_providers != null)
        for (final provider in _providers!) _ProviderCard(provider: provider),
    ],
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.handyman_outlined)),
      title: Text(provider.name),
      subtitle: Text(
        [
          if (provider.category != null) provider.category!,
          if (provider.location != null) provider.location!,
          if (provider.rating != null) '★ ${provider.rating}',
        ].join(' • '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: provider.id.isEmpty
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProviderDetailsPage(providerId: provider.id),
              ),
            ),
    ),
  );
}

class ProviderDetailsPage extends StatefulWidget {
  const ProviderDetailsPage({super.key, required this.providerId});
  final String providerId;

  @override
  State<ProviderDetailsPage> createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  late Future<ServiceProvider> _provider;

  @override
  void initState() {
    super.initState();
    _provider = ServiceBookApi.provider(widget.providerId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_text(context, 'Provider details', 'የአገልግሎት ሰጪ ዝርዝር')),
    ),
    body: FutureBuilder<ServiceProvider>(
      future: _provider,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(
              () => _provider = ServiceBookApi.provider(widget.providerId),
            ),
          );
        }
        final provider = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              provider.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (provider.description != null) ...[
              const SizedBox(height: 8),
              Text(provider.description!),
            ],
            if (provider.availability != null) ...[
              const SizedBox(height: 16),
              Text(
                _text(context, 'Availability', 'ተገኝነት'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(provider.availability.toString()),
            ],
            const SizedBox(height: 16),
            Text(
              _text(context, 'Services', 'አገልግሎቶች'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (provider.services.isEmpty)
              Text(
                _text(context, 'No services listed.', 'ምንም አገልግሎት አልተዘረዘረም።'),
              ),
            for (final service in provider.services)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  (service['name'] ?? service['title'] ?? 'Service').toString(),
                ),
                subtitle: Text((service['description'] ?? '').toString()),
                trailing: Text(
                  service['price'] == null ? '' : service['price'].toString(),
                ),
              ),
            const SizedBox(height: 12),
            if (provider.services.isNotEmpty)
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _BookingDialog(
                    provider: provider,
                    services: provider.services,
                  ),
                ),
                icon: const Icon(Icons.event_available),
                label: Text(_text(context, 'Request booking', 'ቦታ ለመያዝ ጠይቅ')),
              )
            else
              Text(
                _text(
                  context,
                  'Booking is unavailable until this provider publishes a service.',
                  'ይህ አገልግሎት ሰጪ አገልግሎት እስኪያቀርብ ድረስ ቦታ መያዝ አይቻልም።',
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _BookingDialog extends StatefulWidget {
  const _BookingDialog({required this.provider, required this.services});
  final ServiceProvider provider;
  final List<Map<String, dynamic>> services;

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  late String _serviceId;
  late String _meetingMode;
  late DateTime _scheduledAt;
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scheduledAt = DateTime.now().add(const Duration(days: 1));
    final service = widget.services.first;
    _serviceId =
        (service['id'] ?? service['serviceId'] ?? service['service_id'] ?? '')
            .toString();
    _meetingMode = _modesFor(service).first;
  }

  List<String> _modesFor(Map<String, dynamic> service) {
    final serviceModes = service['meetingModes'];
    final providerModes = widget.provider.meetingModes;
    final modes = serviceModes is List
        ? serviceModes.map((mode) => mode.toString()).toList()
        : providerModes;
    return modes
        .where(
          (mode) => const {
            'provider_comes',
            'client_goes',
            'third_location',
          }.contains(mode),
        )
        .toList();
  }

  Map<String, dynamic> get _selectedService => widget.services.firstWhere(
    (service) =>
        (service['id'] ?? service['serviceId'] ?? service['service_id'])
            .toString() ==
        _serviceId,
  );

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_serviceId.isEmpty) {
      setState(
        () => _error = _text(
          context,
          'The service has no ID; booking cannot be submitted.',
          'አገልግሎቱ መለያ የለውም፤ ቦታ ማስያዝ አይቻልም።',
        ),
      );
      return;
    }
    final durationMinutes = int.tryParse(
      (_selectedService['durationMinutes'] ?? '').toString(),
    );
    final latitude = _meetingMode == 'client_goes'
        ? widget.provider.latitude
        : double.tryParse(_latitude.text.trim());
    final longitude = _meetingMode == 'client_goes'
        ? widget.provider.longitude
        : double.tryParse(_longitude.text.trim());
    if (durationMinutes == null || latitude == null || longitude == null) {
      setState(
        () => _error = _text(
          context,
          'This service needs a duration and valid meeting coordinates.',
          'ለዚህ አገልግሎት የቆይታ ጊዜ እና ትክክለኛ የመገናኛ መጋጠሚያዎች ያስፈልጋሉ።',
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await ServiceBookApi.createBooking(
        providerId: widget.provider.id,
        serviceId: _serviceId,
        scheduledAt: _scheduledAt,
        durationMinutes: durationMinutes,
        meetingMode: _meetingMode,
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      if (response['success'] == false) {
        setState(
          () => _error = (response['message'] ?? 'Booking request failed')
              .toString(),
        );
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(context, 'Booking request sent.', 'የቦታ ማስያዣ ጥያቄ ተልኳል።'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_text(context, 'Request booking', 'ቦታ ለመያዝ ጠይቅ')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _serviceId,
          decoration: InputDecoration(
            labelText: _text(context, 'Service', 'አገልግሎት'),
          ),
          items: [
            for (final service in widget.services)
              DropdownMenuItem(
                value:
                    (service['id'] ??
                            service['serviceId'] ??
                            service['service_id'] ??
                            '')
                        .toString(),
                child: Text(
                  (service['name'] ?? service['title'] ?? 'Service').toString(),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            final selected = widget.services.firstWhere(
              (service) =>
                  (service['id'] ??
                          service['serviceId'] ??
                          service['service_id'])
                      .toString() ==
                  value,
            );
            final modes = _modesFor(selected);
            setState(() {
              _serviceId = value;
              if (!modes.contains(_meetingMode)) {
                _meetingMode = modes.first;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _meetingMode,
          decoration: InputDecoration(
            labelText: _text(context, 'Meeting mode', 'የስብሰባ አይነት'),
          ),
          items: [
            for (final mode in _modesFor(_selectedService))
              DropdownMenuItem(
                value: mode,
                child: Text(switch (mode) {
                  'provider_comes' => _text(
                    context,
                    'Provider comes to me',
                    'አገልግሎት ሰጪው ወደ እኔ ይመጣል',
                  ),
                  'client_goes' => _text(
                    context,
                    'I go to the provider',
                    'ወደ አገልግሎት ሰጪው እሄዳለሁ',
                  ),
                  _ => _text(
                    context,
                    'Meet at a third location',
                    'በሌላ ቦታ እንገናኛለን',
                  ),
                }),
              ),
          ],
          onChanged: (value) =>
              setState(() => _meetingMode = value ?? 'provider_comes'),
        ),
        const SizedBox(height: 8),
        if (_meetingMode != 'client_goes') ...[
          TextField(
            controller: _latitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _text(context, 'Meeting latitude', 'የመገናኛ ኬክሮስ'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _longitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _text(context, 'Meeting longitude', 'የመገናኛ ኬንትሮስ'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _scheduledAt,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                  );
                  if (time == null || !context.mounted) return;
                  setState(() {
                    _scheduledAt = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            '${MaterialLocalizations.of(context).formatMediumDate(_scheduledAt)} · '
            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_scheduledAt))}',
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(_text(context, 'Cancel', 'ሰርዝ')),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_text(context, 'Send request', 'ጥያቄ ላክ')),
      ),
    ],
  );
}

class WorkFeedPage extends StatefulWidget {
  const WorkFeedPage({super.key, required this.canCreatePost});
  final bool canCreatePost;

  @override
  State<WorkFeedPage> createState() => _WorkFeedPageState();
}

class _WorkFeedPageState extends State<WorkFeedPage> {
  late Future<List<ServiceWorkPost>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = ServiceBookApi.workFeed();
  }

  void _reload() => setState(() => _posts = ServiceBookApi.workFeed());

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ServiceWorkPost>>(
    future: _posts,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingState();
      }
      if (snapshot.hasError) {
        return _ErrorState(
          message: snapshot.error.toString(),
          onRetry: _reload,
        );
      }
      final posts = snapshot.data!;
      return RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.canCreatePost) ...[
              FilledButton.icon(
                onPressed: () =>
                    showDialog<bool>(
                      context: context,
                      builder: (_) => const _WorkPostDialog(),
                    ).then((created) {
                      if (created == true) _reload();
                    }),
                icon: const Icon(Icons.add),
                label: Text(
                  _text(context, 'Share a work sample', 'የስራ ናሙና አጋራ'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (posts.isEmpty)
              _EmptyState(
                message: _text(
                  context,
                  'No work requests yet.',
                  'ገና የስራ ጥያቄ የለም።',
                ),
              ),
            for (final post in posts)
              Card(
                child: ListTile(
                  title: Text(post.title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      [
                        post.description,
                        if (post.category != null) post.category!,
                        if (post.meetingMode != null) post.meetingMode!,
                        if (post.location != null) post.location!,
                      ].join('\n'),
                    ),
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _WorkPostDialog extends StatefulWidget {
  const _WorkPostDialog();

  @override
  State<_WorkPostDialog> createState() => _WorkPostDialogState();
}

class _WorkPostDialogState extends State<_WorkPostDialog> {
  final _caption = TextEditingController();
  final _area = TextEditingController();
  final _photoUrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    _area.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_caption.text.trim().isEmpty || _photoUrl.text.trim().isEmpty) {
      setState(
        () => _error = _text(
          context,
          'Add a caption and public photo URL to continue.',
          'ለመቀጠል መግለጫ እና ይፋዊ የፎቶ አድራሻ ያስገቡ።',
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await ServiceBookApi.createWorkPost(
        caption: _caption.text,
        area: _area.text,
        photoUrl: _photoUrl.text,
      );
      if (!mounted) return;
      if (response['success'] == false) {
        setState(
          () => _error = (response['message'] ?? 'Post failed').toString(),
        );
        return;
      }
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(context, 'Work sample shared.', 'የስራ ናሙና ተጋርቷል።'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_text(context, 'Share a work sample', 'የስራ ናሙና አጋራ')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_caption, _text(context, 'Caption', 'መግለጫ')),
          const SizedBox(height: 10),
          _field(_area, _text(context, 'Area (optional)', 'አካባቢ (አማራጭ)')),
          const SizedBox(height: 10),
          _field(_photoUrl, _text(context, 'Public photo URL', 'ይፋዊ የፎቶ አድራሻ')),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _submitting ? null : () => Navigator.pop(context, false),
        child: Text(_text(context, 'Cancel', 'ሰርዝ')),
      ),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_text(context, 'Post', 'አውጣ')),
      ),
    ],
  );
}

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key, required this.canManage});
  final bool canManage;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late Future<List<ServiceBooking>> _bookings;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _bookings = ServiceBookApi.bookings();
  }

  void _reload() => setState(() {
    _actionError = null;
    _bookings = ServiceBookApi.bookings();
  });

  Future<void> _setStatus(ServiceBooking booking, String status) async {
    setState(() => _actionError = null);
    try {
      final response = await ServiceBookApi.updateBookingStatus(
        booking.id,
        status,
      );
      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Booking status update failed');
      }
      _reload();
    } catch (error) {
      if (mounted) setState(() => _actionError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ServiceBooking>>(
    future: _bookings,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingState();
      }
      if (snapshot.hasError) {
        return _ErrorState(
          message: snapshot.error.toString(),
          onRetry: _reload,
        );
      }
      final bookings = snapshot.data!;
      return RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_actionError != null)
              _ErrorState(message: _actionError!, onRetry: _reload),
            if (bookings.isEmpty)
              _EmptyState(
                message: _text(context, 'No bookings yet.', 'ገና ቦታ አልተያዘም።'),
              ),
            for (final booking in bookings)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName ??
                            _text(
                              context,
                              'Service booking',
                              'የአገልግሎት ቦታ ማስያዣ',
                            ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          '${_text(context, 'Status', 'ሁኔታ')}: ${booking.status}',
                          if (booking.meetingMode != null) booking.meetingMode!,
                          if (booking.scheduledAt != null)
                            MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(booking.scheduledAt!),
                          if (booking.providerName != null)
                            booking.providerName!,
                          if (booking.clientName != null) booking.clientName!,
                        ].join(' • '),
                      ),
                      if (widget.canManage &&
                          const {
                            'pending',
                            'requested',
                          }.contains(booking.status.toLowerCase()))
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: booking.id.isEmpty
                                  ? null
                                  : () => _setStatus(booking, 'CONFIRMED'),
                              child: Text(_text(context, 'Confirm', 'አረጋግጥ')),
                            ),
                            TextButton(
                              onPressed: booking.id.isEmpty
                                  ? null
                                  : () => _setStatus(booking, 'DECLINED'),
                              child: Text(_text(context, 'Decline', 'አትቀበል')),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  late Future<Map<String, dynamic>?> _identity;
  Future<ServiceProvider>? _provider;

  @override
  void initState() {
    super.initState();
    _identity = SecureStorageService.getUserData();
    _loadProvider();
  }

  void _loadProvider() {
    _provider = _identity.then((user) {
      final id = user?['provider_id'] ?? user?['providerId'] ?? user?['id'];
      if (id == null || id.toString().isEmpty) {
        throw StateError('Your account does not include a provider ID.');
      }
      return ServiceBookApi.provider(id.toString());
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ServiceProvider>(
    future: _provider,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingState();
      }
      if (snapshot.hasError) {
        return _ErrorState(
          message: snapshot.error.toString(),
          onRetry: () => setState(_loadProvider),
        );
      }
      final provider = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(provider.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _text(context, 'Services', 'አገልግሎቶች'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (provider.services.isEmpty)
            _EmptyState(
              message: _text(
                context,
                'No services published.',
                'ምንም አገልግሎት አልታተመም።',
              ),
            ),
          for (final service in provider.services)
            Card(
              child: ListTile(
                leading: const Icon(Icons.handyman_outlined),
                title: Text(
                  (service['name'] ?? service['title'] ?? 'Service').toString(),
                ),
                subtitle: Text((service['description'] ?? '').toString()),
                trailing: Text((service['price'] ?? '').toString()),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _text(context, 'Availability', 'ተገኝነት'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            provider.availability?.toString() ??
                _text(
                  context,
                  'Availability has not been published.',
                  'ተገኝነት አልታተመም።',
                ),
          ),
          if (provider.meetingModes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _text(context, 'Meeting modes', 'የስብሰባ አይነቶች'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(provider.meetingModes.join(', ')),
          ],
          const SizedBox(height: 16),
          Text(
            _text(
              context,
              'Service and availability editing is not enabled in the mobile API contract yet.',
              'የአገልግሎት እና ተገኝነት ማስተካከያ በሞባይል API ውል ገና አልተካተተም።',
            ),
          ),
        ],
      );
    },
  );
}

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.report_gmailerrorred_outlined),
          title: Text(_text(context, 'Report an issue', 'ችግር ሪፖርት አድርግ')),
          subtitle: Text(
            _text(
              context,
              'Send a concern to the SBMS team.',
              'ስጋትዎን ለSBMS ቡድን ይላኩ።',
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const IssueReportPage())),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: Text(_text(context, 'Safety and privacy', 'ደህንነት እና ግላዊነት')),
          subtitle: Text(
            _text(
              context,
              'Share only the information needed for a service request. Use the issue form to report unsafe or inappropriate conduct.',
              'ለአገልግሎት ጥያቄ የሚያስፈልገውን መረጃ ብቻ ያጋሩ። ደህንነት የሌለውን ወይም ተገቢ ያልሆነ ባህሪ ለማሳወቅ የችግር ቅጹን ይጠቀሙ።',
            ),
          ),
        ),
      ),
    ],
  );
}

class IssueReportPage extends StatefulWidget {
  const IssueReportPage({super.key});

  @override
  State<IssueReportPage> createState() => _IssueReportPageState();
}

class _IssueReportPageState extends State<IssueReportPage> {
  final _description = TextEditingController();
  String _category = 'safety';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_description.text.trim().isEmpty) {
      setState(
        () => _error = _text(context, 'Describe the issue.', 'ችግሩን ይግለጹ።'),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await ServiceBookApi.createIssue(
        category: _category,
        description: _description.text,
      );
      if (!mounted) return;
      if (response['success'] == false) {
        setState(
          () => _error = (response['message'] ?? 'Report failed').toString(),
        );
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(context, 'Issue report submitted.', 'የችግር ሪፖርቱ ተልኳል።'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_text(context, 'Report an issue', 'ችግር ሪፖርት አድርግ')),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _text(
            context,
            'For immediate danger, contact local emergency services first.',
            'አስቸኳይ አደጋ ካለ መጀመሪያ የአካባቢዎን የአደጋ ጊዜ አገልግሎት ያነጋግሩ።',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: InputDecoration(
            labelText: _text(context, 'Issue type', 'የችግር አይነት'),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'safety',
              child: Text(_text(context, 'Safety concern', 'የደህንነት ስጋት')),
            ),
            DropdownMenuItem(
              value: 'service',
              child: Text(_text(context, 'Service issue', 'የአገልግሎት ችግር')),
            ),
            DropdownMenuItem(
              value: 'conduct',
              child: Text(
                _text(context, 'Inappropriate conduct', 'ተገቢ ያልሆነ ባህሪ'),
              ),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text(_text(context, 'Other', 'ሌላ')),
            ),
          ],
          onChanged: (value) => setState(() => _category = value ?? 'other'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: _text(context, 'Describe what happened', 'የተፈጠረውን ይግለጹ'),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_text(context, 'Submit report', 'ሪፖርት ላክ')),
        ),
      ],
    ),
  );
}

class StaffOverviewPage extends StatelessWidget {
  const StaffOverviewPage({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        _text(context, 'ServiceBook workspace', 'የServiceBook የስራ ቦታ'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        _text(
          context,
          '${_roleName(context, role)} access is ready. Use the work feed and bookings tabs to review shared work and booking activity.',
          'የ${_roleName(context, role)} መዳረሻ ዝግጁ ነው። የተጋሩ ስራዎችን እና ቦታ ማስያዣዎችን ለመመልከት የስራ ማስታወቂያዎችን እና ቦታ ማስያዣዎችን ይጠቀሙ።',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _text(
          context,
          'Role-specific administration and support queues are not included in the mobile API contract yet.',
          'ለዚህ ሚና የተለየ የአስተዳደር እና የድጋፍ ስራ ዝርዝር በሞባይል API ውል ገና አልተካተተም።',
        ),
      ),
    ],
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  int maxLines = 1,
}) => TextField(
  controller: controller,
  keyboardType: keyboardType,
  maxLines: maxLines,
  decoration: InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
  ),
);

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(_text(context, 'Retry', 'እንደገና ሞክር')),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}
