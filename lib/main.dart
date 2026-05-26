import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'crop_library.dart';
import 'data/acvm_product_repository.dart';
import 'data/local_garden_repository.dart';
import 'data/open_meteo_service.dart';
import 'data/openfarm_service.dart';
import 'features/seedlings/data/grow_time_service.dart';
import 'features/notifications/harvest_reminder_service.dart';
import 'models/garden_snapshot.dart';
import 'models/openfarm_crop.dart';
import 'models/spray_condition.dart';
import 'models/spray_product.dart';
import 'services/storage/garden_backup_file_service.dart';

part 'core/app_shell.dart';
part 'features/seedlings/domain/planting_calendar.dart';
part 'features/seedlings/domain/seedling_models.dart';
part 'features/garden/domain/garden_models.dart';
part 'features/spray/domain/spray_records.dart';
part 'features/spray/domain/spray_advisor.dart';
part 'features/garden/domain/bed_suggestions.dart';
part 'features/protection/domain/protection_calendar.dart';
part 'features/home/presentation/home_controller.dart';
part 'features/home/presentation/home_screen.dart';
part 'features/weather/presentation/weather_panels.dart';
part 'features/home/presentation/widgets/home_widgets.dart';
part 'features/garden/presentation/pages/garden_screen.dart';
part 'features/calendar/presentation/spray_feed_calendar_screen.dart';
part 'features/garden/presentation/widgets/bed_operations.dart';
part 'features/garden/presentation/widgets/garden_planner_legacy.dart';
part 'features/seedlings/presentation/seedlings_screen.dart';
part 'features/spray/presentation/pages/spray_screens.dart';
part 'features/garden/presentation/widgets/crop_planner.dart';
part 'features/crops/presentation/widgets/openfarm_widgets.dart';
part 'features/protection/presentation/protection_screen.dart';
part 'common/widgets/shared_widgets.dart';

void main() => runApp(const SprayTrackerApp());
