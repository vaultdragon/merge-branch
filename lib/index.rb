require 'json'
require 'octokit'
require_relative './services/merge_branch_service'

def presence(value)
  return nil if value == ""
  value
end

Octokit.configure do |c|
  c.api_endpoint = ENV['GITHUB_API_URL']
end

puts File.read(ENV['GITHUB_EVENT_PATH'])
puts ENV.inspect

@event = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
@head_to_merge = presence(ENV['INPUT_HEAD_TO_MERGE']) || presence(ENV['INPUT_FROM_BRANCH']) || presence(ENV['GITHUB_SHA']) # or brach name
@repository = ENV['GITHUB_REPOSITORY']
@github_token = presence(ENV['INPUT_GITHUB_TOKEN']) || presence(ENV['GITHUB_TOKEN'])

inputs = {
  type: presence(ENV['INPUT_TYPE']) || MergeBrachService::TYPE_LABELED, # labeled | comment | now
  label_name: ENV['INPUT_LABEL_NAME'],
  target_branch: ENV['INPUT_TARGET_BRANCH']
}

MergeBrachService.validate_inputs!(inputs)
service = MergeBrachService.new(inputs, @event)

puts service.inspect

if service.valid?
  @client = Octokit::Client.new(access_token: @github_token)
  puts "Running perform merge target_branch: #{inputs[:target_branch]} @head_to_merge: #{@head_to_merge}}"

  comparison = @client.compare(@repository, inputs[:target_branch], @head_to_merge)

  #if comparison.status == 'diverged'
#
 # end

  puts comparison.status
  puts comparison.files.length()
  puts comparison.files.inspect


 # @client.merge(@repository, inputs[:target_branch], @head_to_merge, ENV['INPUT_MESSAGE'] ? {commit_message: ENV['INPUT_MESSAGE']} : {})
  puts "Completed: Finish merge branch #{@head_to_merge} to #{inputs[:target_branch]}"
else
  puts "Neutral: skip merge target_branch: #{inputs[:target_branch]} @head_to_merge: #{@head_to_merge}"
end
