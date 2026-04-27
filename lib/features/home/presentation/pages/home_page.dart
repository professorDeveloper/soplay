import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home_event.dart';
import 'package:soplay/features/home/presentation/bloc/home_state.dart';
import 'package:soplay/features/home/presentation/widgets/home_content.dart';
import 'package:soplay/features/home/presentation/widgets/home_state_views.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoad());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const HomeSkeleton();
        }
        if (state is HomeError) return const HomeErrorView();
        if (state is HomeLoaded) return HomeContent(state: state);
        return const SizedBox.shrink();
      },
    );
  }
}
