library movies;

import 'dart:html';
import 'dart:async';

import 'package:polymer/polymer.dart';
 
import '../models.dart';
import '../services.dart';
import '../utils.dart';


@CustomTag('movie-posters')
class MoviesGridUI extends PolymerElement {
  
  @observable
  Iterable<Movie> movies = toObservable(new List());
  @observable String sortField = "";
  @observable bool sortAscending = true;
  
  List<Menu> menus = new List();
  Menu _currentMenu;
  
  @observable String searchFilter = "";
  @observable String searchTerm = "";
  
  MoviesGridUI.created() : super.created() {
    Menu homeMenu = new Menu(0, "All", moviesService.getAllMovies, true);
    menus.add(homeMenu);
    menus.add(new Menu(1, "Now playing", _retrieveNowPlaying));
    menus.add(new Menu(2, "Upcoming", _retrieveUpcoming));
    menus.add(new Menu(3, "Top rated TV Series", _retrieveTopRatedTV));
    menus.add(new Menu(4, "Favorites", moviesService.getFavorites));
    _applyMenu(homeMenu);
  }
  
  bool get applyAuthorStyles => true;
  
  /// Applies a menu : retrieves the new list according to the menu and updates movies list
  _applyMenu(Menu menu) {
    menu.retriever().then((Iterable<Movie> m) => movies = m);
    _currentMenu = menu;
  }
  
  _retrieveNowPlaying() => moviesService.getMovies("now_playing");
  _retrieveUpcoming() => moviesService.getMovies("upcoming");
  _retrieveTopRatedTV() => moviesService.getMovies("tv_top_rated");
  _retrieveFavorites() => moviesService.getFavorites();
  
  /// The search term has been changed (automatically called when the observable searchTerm is modified)
  Timer searchTermTimer = null;
  searchTermChanged(String oldValue) {
    // If there's an active timer then reset it
    if (searchTermTimer != null && searchTermTimer.isActive) searchTermTimer.cancel();
    // Apply the searchTerm to the searchFilter after a certain amout of time
    searchTermTimer = new Timer(new Duration(milliseconds: 400), () {
      searchFilter = searchTerm;
      searchTermTimer = null;
    });
  }
  
  /// Filters movies according to the search term
  filter(String search) => (Iterable<Movie> movies) => searchFilter.isNotEmpty ? movies.where((Movie m) => m.title.toLowerCase().contains(searchFilter.toLowerCase())).toList() : movies;
    
  /// Sort according to a field's name : if this field is already the current sorting field then reverse the sort
  sortBy(String field, bool ascending) => (Iterable games) {
    var list = games.toList()..sort(Movie.getComparator(field));
    return ascending ? list : list.reversed;
  };
  
  /// A menu has been selected
  selectMenu(Event e, var detail, Element target) {
    int menuId = int.parse(target.dataset['menuid']);
    if (applySelectedCSS(target, "item")) {
      _applyMenu(menus[menuId]);
    }
  }
  
  /// A movie's favorite attribute has been modified
  updateFavorite(Event e, Movie detail, Element target) {
    moviesService.save(detail);
    // In case the current menu is favorite, then remove the movie if it's not more a favorite
    if (_currentMenu != null && _currentMenu.id == 4 && !detail.favorite) movies = movies.where((Movie m) => m != detail).toList();
  }
  
  /// A sort button has been clicked
  sort(Event e, var detail, Element target) {
    var field = target.dataset['field'];
    sortAscending = field == sortField ? !sortAscending : true;
    sortField = field;
    applySelectedCSS(target, "gb");
  }
}

