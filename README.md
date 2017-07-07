# AnomalyDetect

Anomaly Detection functions - PostgreSQL only at the moment

Can be used in ActiveRecord or directly in SQL.

Supports 3 types of anomaly detection:

- static thresholds
- percentage of mean
- z-score

```ruby
Order.anomaly_detect_static('created_at', 'created_at', '2017-01-01', '2017-07-07', 'day', 1);
```

Can be directly used in SQL
```sql
select * from anom_detect_static('orders', 'created_at', 'created_at', '2017-01-01', '2017-07-07', 'day', 1);
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'anomlaly_detect'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install anomlaly_detect

## Usage

Create a migration to add the anomaly detection functions to the database.

```ruby
def up
  AnomalyDetection.create_function
end

def down
  AnomalyDetection.drop_function
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/anomlaly_detect. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
