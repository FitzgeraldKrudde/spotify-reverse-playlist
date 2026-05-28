#!/bin/bash
#
# This script creates a new playlist in your account with all the tracks reversed.
#
# This is very convenient for top-lists which are usually sorted starting with number 1.
# Currently (Jan 2018) the Spotify clients do not enable you to play a playlist in reversed order.
#
# Just invoke this script without parameters to get the usage.
#
#
# Fitzgerald Jan 2018
#

# This scripts has a few dependencies on some (standard Linux) commands:
# base64
# jq
# curl
# nc
# tac

#
# The script will check for these dependencies.
#

#
# The source for this script is on Github: https://github.com/FitzgeraldKrudde/spotify-reverse-playlist
#

#
# Spotify application ID (reverse-playlist)
#
CLIENT_ID="c6ca1fca1b374acb857021f5907d8ea5"
CLIENT_SECRET="3cfe8ca8492f4db0a49e85dde5af34d7"

#
# base64 clientid/clientsecret
#
b64_client_id_secret=$(echo -ne "${CLIENT_ID}":"${CLIENT_SECRET}" | base64 --wrap=0)
b64_client_id_secret=$(printf "${CLIENT_ID}":"${CLIENT_SECRET}" | base64 --wrap=0)

#
# listen port for nc callback
#
PORT=8888
#
# redirect URL after providing access
#
REDIRECT_URI="http://127.0.0.1:${PORT}"

#
# Spotify REST stuff
#
SPOTIFY_API_TOKEN="https://accounts.spotify.com/api/token"
SPOTIFY_API_AUTHORIZE="https://accounts.spotify.com/authorize/"
SPOTIFY_API_BASE_URL="https://api.spotify.com/v1"
SPOTIFY_API_ME_URL="${SPOTIFY_API_BASE_URL}/me"
SPOTIFY_API_SCOPES=$(echo "playlist-read-private playlist-modify-public playlist-modify-private user-read-private" | tr ' ' '%' | sed s/%/%20/g)
SPOTIFY_ACCEPT_HEADER="Accept: application/json"
SPOTIFY_CONTENT_TYPE_HEADER="Content-Type: application/json"
CURL_OPTIONS="--silent"
#CURL_OPTIONS=""

#
# functions
#
usage() {
	echo "usage: $0 <playlist-id> [new-playlist-name] [new-playlist-description]"
	echo ""
	echo "This script reverses the tracks in a playlist."
	echo "The only required parameter is playlist-id."
	echo "A new playlist in your account will be created with the tracks reversed."
	echo ""
	echo "For the new playlist the default name/description is:"
	echo "name: '<current-name> reversed'"
	echo "description: '<current-description> (reversed)'"
	echo "If you want to use something else then provide the parameters."
	echo ""
	echo "The easiest way to find the playlist-iduserid:"
	echo "use the Spotify web player (https://open.spotify.com) and go to the playlist."
	echo "For example: https://open.spotify.com/playlist/7DSznpxTfYe9h2S6lxLXar"
	echo ""
	echo "playlist-id -> 7DSznpxTfYe9h2S6lxLXar"
}

checkForErrorInResponse() {
	local response=$1
	local error=$(echo ${response} | jq --raw-output '.error')
	if [[ "${error}" != "null" ]]
	then
		echo "failed with the following error:"
		echo "${error}"
		echo "exiting.."
		exit 1
	fi
}

checkForBinary() {
	local cmd=$1
	if ! which $cmd > /dev/null
	then
		echo "missing binary: $cmd"
		echo "exiting..."
		exit 2
	fi
}

checkForBrewBinary() {
	local cmd=$1
	if ! ls -l $(which $cmd) | grep brew > /dev/null
	then
		echo "missing binary from brew: $cmd"
		echo "exiting..."
		exit 2
	fi
}

#
# /functions
#

#
# start script
#

#
# check for prerequisite binaries
#
checkForBinary base64
checkForBinary jq
checkForBinary curl
checkForBinary nc
tac() { tail -r ; }

#
# check for required parameter source_playlist_id
#
if [[ "${#}" -lt "1" ]]
then
	usage
	exit 1
else
	source_playlist_id="${1}"
	echo "source_playlist_id: $source_playlist_id"
fi

#
# read optional parameters
# 
if [[ -n $2 ]]
then
	destination_playlist_name="${3}"
	echo "destination_playlist_name: $destination_playlist_name"
fi
if [[ -n $3 ]]
then
	destination_playlist_description="${4}"
	echo "destination_playlist_description: $destination_playlist_description"
fi

#
# send the user to the Spotify URL for authorization
#
authorization_endpoint="${SPOTIFY_API_AUTHORIZE}?response_type=code&client_id=${CLIENT_ID}&scope=${SPOTIFY_API_SCOPES}&redirect_uri=${REDIRECT_URI}"
echo "Go to this URL to authorize this script: $authorization_endpoint"
echo "After authorization this script will pickup the authorization code"
response=$(printf 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 0\r\nAccess-Control-Allow-Origin:*\r\nConnection: Close\r\n\r\nDone!\r\n\r\n\r\n' | nc -l "${PORT}")
authorization_code=$(echo "${response}" | grep GET | cut -d ' ' -f 2 | cut -d '=' -f 2)
echo "Got authorization code: ${authorization_code}"

#
# get a Spotify access token for this authorization code
#
response=$(curl ${CURL_OPTIONS} --header "Content-Type:application/x-www-form-urlencoded" --header "Authorization: Basic $b64_client_id_secret" --data "grant_type=authorization_code&code=${authorization_code}&redirect_uri=${REDIRECT_URI}" ${SPOTIFY_API_TOKEN})
checkForErrorInResponse "${response}"
spotify_access_token=$(echo "${response}" | jq --raw-output '.access_token')

#
# define the Spotify authorization header
#
spotify_authorization_header="Authorization: Bearer ${spotify_access_token}"

#
# get info for the current Spotify user
#
response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${SPOTIFY_API_ME_URL}")
checkForErrorInResponse "${response}"
current_spotify_user=$(echo ${response} | jq --raw-output '.display_name')
echo "current_spotify_user: ${current_spotify_user}"
current_spotify_user_id=$(echo ${response} | jq --raw-output '.id')
echo "current_spotify_user_id: ${current_spotify_user_id}"

#
# get the playlist info
#
response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${SPOTIFY_API_BASE_URL}/playlists/${source_playlist_id}")
checkForErrorInResponse "${response}"
playlist_api_url=$(echo ${response} | jq --raw-output '.tracks.href')
source_playlist_url=$(echo ${response} | jq --raw-output '.external_urls.spotify')

# set name of the new playlist based on the retrieved playlist (if a name has not been provided on the commandline)
#
if [[ -z ${destination_playlist_name} ]]
then
	playlist_name=$(echo ${response} | jq --raw-output '.name')
	destination_playlist_name="${playlist_name} reversed"
fi

#
# set description of the new playlist based on the retrieved playlist (if a name has not been provided on the commandline)
#
if [[ -z ${destination_playlist_description} ]]
then
	playlist_description=$(echo ${response} | jq --raw-output '.description')
	destination_playlist_description="${playlist_description} reversed"
fi

#
# get the tracks of the playlist (first 100)
#
response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${playlist_api_url}")
checkForErrorInResponse "${response}"
all_tracks=$(echo ${response} | jq --raw-output '.items[].track.uri')
next=$(echo ${response} | jq --raw-output '.next')
printf "#retrieved tracks: %s" "$(printf '%s\n' ${all_tracks} | wc -w | tr -d '[:space:]')"

##
# if there are more tracks (next uri != null), retrieve them
#
while [ "${next}" != "null" ]
do
	response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${next}")
	checkForErrorInResponse "${response}"
	tracks=$(echo ${response} | jq --raw-output '.items[].track.uri')
	all_tracks="${all_tracks}
${tracks}"
	next=$(echo ${response} | jq --raw-output '.next')
	printf " %s" "$(printf '%s\n' ${all_tracks} | wc -w | tr -d '[:space:]')"
done

#
# 1 track per line
#
all_tracks="$(printf '%s\n' ${all_tracks})"
nr_tracks=$(printf '%s\n' "${all_tracks}" | wc -l | tr -d '[:space:]')
echo ""
echo "#tracks read from playlist: ${nr_tracks}"

#
# filter local tracks as the API does not allow them..
#
nr_local_tracks="$(printf '%s\n' ${all_tracks} | grep -c 'spotify:local' || true)"
if [[ "${nr_local_tracks}" != "0" ]]
then
	echo "ignoring ${nr_local_tracks} local tracks as the Spotify API cannot handle them"
	all_tracks="$(printf '%s\n' ${all_tracks} | grep -v 'spotify:local')"
	echo "#tracks after filtering out local tracks: $(printf '%s\n' "${all_tracks}" | wc -l | tr -d '[:space:]')"
fi

#
# reverse the tracks
#
tracks_reversed=$(printf '%s\n' ${all_tracks} | tac)
echo "#tracks_reversed: $(printf '%s\n' "${tracks_reversed}" | wc -l | tr -d '[:space:]')"

#
# create a new playlist
#
body=$(jq --null-input --arg name "${destination_playlist_name}" --arg description "${destination_playlist_description}" '{name:$name, description:$description, public:true}')
response=$(curl ${CURL_OPTIONS} --request POST "${SPOTIFY_API_BASE_URL}/users/${current_spotify_user_id}/playlists" --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" --header "${SPOTIFY_CONTENT_TYPE_HEADER}" --data "${body}")
checkForErrorInResponse "${response}"
destination_playlist_id=$(echo ${response} | jq --raw-output '.id')
destination_playlist_url=$(echo ${response} | jq --raw-output '.external_urls.spotify')
echo "Created a new playlist, id: ${destination_playlist_id}"

#
# add one track at a time with 2s delay + retry on rate limit
#
printf "Adding %s tracks to the new playlist: " "${nr_tracks}"
while read track
do
	retry_count=0
	max_retries=5
	while [ $retry_count -lt $max_retries ]; do
		body=$(jq --null-input --arg uri "${track}" '{uris:[$uri]}')
		tmpfile=$(mktemp)
		http_code=$(curl ${CURL_OPTIONS} -o "$tmpfile" -w "%{http_code}" \
			--request POST "${SPOTIFY_API_BASE_URL}/users/${current_spotify_user_id}/playlists/${destination_playlist_id}/tracks" \
			--header "${SPOTIFY_ACCEPT_HEADER}" \
			--header "${SPOTIFY_CONTENT_TYPE_HEADER}" \
			--header "${spotify_authorization_header}" \
			--data "${body}")

		if [ "$http_code" = "429" ] || [ "$http_code" -ge 500 ]; then
			rm -f "$tmpfile"
			echo ""
			echo "HTTP $http_code, retrying in 5s..."
			sleep 5
			retry_count=$((retry_count + 1))
		elif [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
			rm -f "$tmpfile"
			break
		else
			echo ""
			echo "Unexpected HTTP $http_code, response:"
			head -5 "$tmpfile"
			rm -f "$tmpfile"
			exit 1
		fi
	done
	if [ $retry_count -ge $max_retries ]; then
		echo "Max retries reached, exiting."
		exit 1
	fi
	printf "."
	sleep 2
done < <(printf '%s\n' ${tracks_reversed})
echo ""

#
# finished
#
echo ""
echo "Finished successfully. URL of the new playlist: ${destination_playlist_url}"


