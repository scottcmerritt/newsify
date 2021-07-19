class GoogleAnalyze

  def initialize opts = {}

  end


  def entities_from_text text_content:
    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    result = language.analyze_entities document: document

    entities = result.entities
    #return entities
=begin
    @rows = []
    entities.each do |entity|
      #new_row = {name: entity.name,:type=>entity.type,:salience=>entity.salience,:wiki_url=>entity.metadata['wikipedia_url']}
      wiki_url = entity.metadata['wikipedia_url'].to_s if entity.metadata['wikipedia_url']
      row = Newsify::EntityRow.new({name: entity.name.to_s,type: entity.type.to_s,salience: entity.salience,wiki_url: wiki_url})
      @rows.push row
      #puts "Entity #{entity.name} #{entity.type}"

      #puts "URL: #{entity.metadata['wikipedia_url']}" if entity.metadata["wikipedia_url"]
    end
    return 100
  #  return @rows
=end
  end

  def classify_from_text text_content:
    require "google/cloud/language"
    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.classify_text document: document

    categories = response.categories
    res = []
    categories.each do |category|
      res.push({name: category.name,confidence:category.confidence})
    end
    res
  end

  def sentiment_from_text text_content:
    # [START language_sentiment_text]
    # text_content = "Text to run sentiment analysis on"

    require "google/cloud/language"
=begin
  client = Google::APIClient.new(
  application_name: 'Your Google API Application',
  application_version: YOUR_VERSION
)
client.authorization = 
Google::APIClient::ClientSecrets.load(
  File.join(
    Rails.root,
    'config',
    'client_secret-000000000-aaaaaaaaaa0a.apps.googleusercontent.json'
  )
).to_authorization
=end

    language = Google::Cloud::Language.language_service
  #language = Google::Cloud::Language.configure({credentials: JSON.parse(ENV.fetch('GOOGLE_API_CREDS'))})

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.analyze_sentiment document: document

    sentiment = response.document_sentiment

    puts "Overall document sentiment: (#{sentiment.score})"
    puts "Sentence level sentiment:"

    sentences = response.sentences

    res = []
    sentences.each do |sentence|
      sentiment = sentence.sentiment
      res.push "#{sentence.text.content}: (#{sentiment.score})"
    end
    # [END language_sentiment_text]
    res
  end

  def sentiment_from_cloud_storage_file storage_path:
    # [START language_sentiment_gcs]
    # storage_path = "Path to file in Google Cloud Storage, eg. gs://bucket/file"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { gcs_content_uri: storage_path, type: :PLAIN_TEXT }
    response = language.analyze_sentiment document: document

    sentiment = response.document_sentiment

    puts "Overall document sentiment: (#{sentiment.score})"
    puts "Sentence level sentiment:"

    sentences = response.sentences

    sentences.each do |sentence|
      sentiment = sentence.sentiment
      puts "#{sentence.text.content}: (#{sentiment.score})"
    end
    # [END language_sentiment_gcs]
  end

  def entities_from_text text_content:
    # [START language_entities_text]
    # text_content = "Text to extract entities from"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.analyze_entities document: document

    entities = response.entities

    entities.each do |entity|
      puts "Entity #{entity.name} #{entity.type}"

      puts "URL: #{entity.metadata['wikipedia_url']}" if entity.metadata["wikipedia_url"]
    end
    # [END language_entities_text]
  end

  def entities_from_cloud_storage_file storage_path:
    # [START language_entities_gcs]
    # storage_path = "Path to file in Google Cloud Storage, eg. gs://bucket/file"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { gcs_content_uri: storage_path, type: :PLAIN_TEXT }
    response = language.analyze_entities document: document

    entities = response.entities

    entities.each do |entity|
      puts "Entity #{entity.name} #{entity.type}"

      puts "URL: #{entity.metadata['wikipedia_url']}" if entity.metadata["wikipedia_url"]
    end
    # [END language_entities_gcs]
  end

  def syntax_from_text text_content:
    # [START language_syntax_text]
    # text_content = "Text to analyze syntax of"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.analyze_syntax document: document

    sentences = response.sentences
    tokens    = response.tokens

    puts "Sentences: #{sentences.count}"
    puts "Tokens: #{tokens.count}"

    tokens.each do |token|
      puts "#{token.part_of_speech.tag} #{token.text.content}"
    end
    # [END language_syntax_text]
  end

  def syntax_from_cloud_storage_file storage_path:
    # [START language_syntax_gcs]
    # storage_path = "Path to file in Google Cloud Storage, eg. gs://bucket/file"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { gcs_content_uri: storage_path, type: :PLAIN_TEXT }
    response = language.analyze_syntax document: document

    sentences = response.sentences
    tokens    = response.tokens

    puts "Sentences: #{sentences.count}"
    puts "Tokens: #{tokens.count}"

    tokens.each do |token|
      puts "#{token.part_of_speech.tag} #{token.text.content}"
    end
    # [END language_syntax_gcs]
  end

  def classify_text text_content:
    # [START language_classify_text]
    # text_content = "Text to classify"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.classify_text document: document

    categories = response.categories

    categories.each do |category|
      puts "Name: #{category.name} Confidence: #{category.confidence}"
    end
    # [END language_classify_text]
  end

  def classify_text_from_cloud_storage_file storage_path:
    # [START language_classify_gcs]
    # storage_path = "Path to file in Google Cloud Storage, eg. gs://bucket/file"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { gcs_content_uri: storage_path, type: :PLAIN_TEXT }
    response = language.classify_text document: document

    categories = response.categories

    categories.each do |category|
      puts "Name: #{category.name} Confidence: #{category.confidence}"
    end
    # [END language_classify_gcs]
  end

  def analyze_entity_sentiment text_content:
    # [START language_entity_sentiment_text]
    # text_content = "Text to analyze"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.analyze_entity_sentiment document: document

    response.entities.each do |entity|
      puts "Entity: #{entity.name} Sentiment: #{entity.sentiment.score}"
    end
    # [END language_entity_sentiment_text]
  end

  def analyze_entity_sentiment_from_storage_file storage_path:
    # [START language_entity_sentiment_gcs]
    # storage_path = "Path to file in Google Cloud Storage, eg. gs://bucket/file"

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { gcs_content_uri: storage_path, type: :PLAIN_TEXT }
    response = language.analyze_entity_sentiment document: document

    response.entities.each do |entity|
      puts "Entity: #{entity.name} Sentiment: #{entity.sentiment.score}"
    end
    # [END language_entity_sentiment_gcs]
  end

  if $PROGRAM_NAME == __FILE__

    if ARGV.length == 1
      puts "Sentiment:"
      sentiment_from_text text_content: ARGV.first
      puts "Entities:"
      entities_from_text text_content: ARGV.first
      puts "Syntax:"
      syntax_from_text text_content: ARGV.first
      puts "Classify:"
      classify_text text_content: ARGV.first
    else
      puts "Usage: ruby language_samples.rb <text-to-analyze>"
    end
  end

end