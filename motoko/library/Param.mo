/// Parameters to the service's publicly visible behavior
module {
  /// Time mode.
  ///
  /// Controls how the actor records time and names unique IDs.
  ///
  /// For deployment (timeMode = #ic), the time is system time (nanoseconds since 1970-01-01).
  ///
  /// For scripts and CI-based testing, we want to predict and control time from a #script.
  public type TimeMode = {
    // deterministic, small-number times in scripts.
    #script; 
    // IC determines time.
    #ic;
  };
  public let timeMode : TimeMode = #ic;

  /// Recent past duration of time.
  ///
  /// Users may not super like more than a limited number of videos per this duration of time.
  ///
  /// The units depends on the value of `timeMode`.
  /// Time units is nanoseconds (since 1970-01-01) when timeMMode is #ic.
  /// Time units is script-determined (often beginning at 0) when timeMode is #script.
  ///
  public let recentPastDuration : Int = 50_000_000_000;

}
