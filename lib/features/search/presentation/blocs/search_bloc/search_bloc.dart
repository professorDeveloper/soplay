import 'package:flutter_bloc/flutter_bloc.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent,SearchState> {

	SearchBloc() : super(const SearchInitial()) {
		on<SearchEvent>((event, emit) async {

		});
	}
}