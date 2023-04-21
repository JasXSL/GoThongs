#ifndef _lib_sounds
#define _lib_sounds


// trigger random squish
#define squishSound() llTriggerSound(randElem((list)"72d65db8-31fe-375b-8716-89e3963fbf7d"+"90b0ec1a-d5d2-3e18-ed0d-c5fb7c6885fd"+"f9194db3-9606-2264-3cde-765430179069"), llFrand(0.25)+0.25)
#define tentSlapSound() llTriggerSound(randElem((list)"79448c2b-b60f-ceb9-e05e-cd1d3a27cfc0"+"0e925339-fc8b-d7fc-0c2d-91a168134137"+"ffc6431e-9b21-cafd-9158-e22e7b328b86"+"81ae340e-56c2-72d4-9011-832ed81a3f9f"), llFrand(0.5)+0.5)
#define spankSound() llTriggerSound(randElem((list)"f8dad0f8-2ffc-ccbf-d115-8a8808722690"+"dcbfcb36-b84d-809f-c07b-cb0ab61d3cd8"+"76716856-edc6-6d7c-dbc9-7ec23723c6f6"), llFrand(0.5)+0.5)




#define gotSoundLib$goblin$aggro "a1d027fa-579d-8e7e-debc-633069560a15"
#define gotSoundLib$goblin$aggro_lost "0e45ec66-d02b-f8cf-68e6-66b1b24c475f"
#define gotSoundLib$goblin$takehit "8d996a4b-03a5-f89a-4758-893d894f3ffd"
#define gotSoundLib$goblin$attack "b55d7cc0-a37a-4e96-0b53-2773ff7fe5aa"
#define gotSoundLib$goblin$death "7bceac87-fc92-ce91-8918-80d949c968e8"

#define gotSoundLib$splatter$aggro "83417238-ee74-84fa-4d54-e90d6aa4cf88"
#define gotSoundLib$splatter$takehit "f12d384c-4c15-a34d-3962-964968a32ff3"

#define gotSoundLib$blueglob$aggro "6b53ba91-3aa8-3e90-3bc2-7063520ce8e2"
#define gotSoundLib$blueglob$aggro_lost "c6b08c80-eae3-4a75-f30f-d34c1b95f66e"
#define gotSoundLib$blueglob$takehit "90934dde-7e10-89e2-404f-db9e1f829094"
#define gotSoundLib$blueglob$attack "e442ab54-aa9f-c42f-0646-3c034a0abbcf"
#define gotSoundLib$blueglob$death "ca2d9f5d-2768-edc9-a989-885c80df5cc3"

#define gotSoundLib$gnoll$aggro "d588dc90-8be9-c3df-582d-dcdae7f661c2"
#define gotSoundLib$gnoll$takehit "def51018-d4a0-a6af-492b-b34e25c04ee5"
#define gotSoundLib$gnoll$attack "be42c330-f776-325a-059d-7edcf1328b8c"
#define gotSoundLib$gnoll$death "86c3ac10-bbd1-51ee-0bcf-660190b020e9"

#define gotSoundLib$vibbee$aggro "e40db27c-414c-22b6-14c5-aaee8f020233"
#define gotSoundLib$vibbee$takehit "d09a158b-5b72-b38f-3835-3eb813aeb684"
#define gotSoundLib$vibbee$attack "274010a7-ca53-2fa5-a7db-e9bdd5f4bd62"
#define gotSoundLib$vibbee$death "c364020a-8ad2-b69b-3c7f-92e01746b8b7"

#define gotSoundLib$firesprite$aggro "77df7327-a8a1-4158-1c2b-461574ffa588"
#define gotSoundLib$firesprite$takehit "31a1f9b4-4d1a-21c6-eb4d-76b04f5a485e"
#define gotSoundLib$firesprite$attack "e3db24cb-b107-fe89-b675-9fe572c5ce54"
#define gotSoundLib$firesprite$death "eee95075-2e10-a2b0-f702-281f2594c047"

#define gotSoundLib$fireprimal$aggro "d683f8f8-70d5-f342-edd2-6fca527e2c0f"
#define gotSoundLib$fireprimal$takehit "9a175490-9a3c-7024-dc5e-25df73914ad1"
#define gotSoundLib$fireprimal$attack "98211081-df54-21d3-8dff-472e2bfcb9ba"
#define gotSoundLib$fireprimal$death "06a11ccb-ec01-fd25-3c41-d0fd7898b37c"


#define gotSoundLib$watersprite$aggro "e099fd20-6d28-1ea3-401a-a2eb790e0930"
#define gotSoundLib$watersprite$takehit "33763d1c-1b0b-e610-049d-bcb44f9f8428"
#define gotSoundLib$watersprite$attack "4b7e43f1-575f-7a91-8d0c-f77fddd4f018"
#define gotSoundLib$watersprite$death "482ca408-7219-8e13-774b-ad4eb23ef9f1"

#define gotSoundLib$icesprite$aggro "dfb42fc7-8257-0038-3b36-2e497f966500"
#define gotSoundLib$icesprite$takehit "f4ea04dd-2535-d915-a5e5-281b8d27040b"
#define gotSoundLib$icesprite$attack "9c61aa88-1661-f309-b212-a761c6622fb8"
#define gotSoundLib$icesprite$death "8eb38844-852a-c354-a658-0e7f2849cc39"

#define gotSoundLib$earthsprite$aggro "8e6de4f0-44c3-8476-7275-823209475e47"
#define gotSoundLib$earthsprite$takehit "99af8bf7-bcd5-64a4-a8a2-23cebb7e9c35"
#define gotSoundLib$earthsprite$attack "b83decd7-abf9-999a-a03b-8007c7783e80"
#define gotSoundLib$earthsprite$death "b2cb67ba-568d-ab1a-6bff-ed08a54a7b5d"

#define gotSoundLib$windsprite$aggro "c2886de8-b3d5-70d9-e1a6-a6fc474f4997"
#define gotSoundLib$windsprite$takehit "32e49bd1-6644-60c4-1d17-71a58fc9926b"
#define gotSoundLib$windsprite$attack "33b4114b-40cf-590e-c268-c54799ebb837"
#define gotSoundLib$windsprite$death "90aab779-07a7-47af-ef56-7ccd30e6a1aa"

#define gotSoundLib$earthprimal$aggro "db71790a-f9de-3b1d-84f9-a0e088dcfceb"
#define gotSoundLib$earthprimal$takehit "10c7106a-bea8-11b8-1bf8-4a709ac2b99a"
#define gotSoundLib$earthprimal$attack "d3cb6764-eea9-20ad-42e6-a71b300fbb23"
#define gotSoundLib$earthprimal$death "f0e4f4ce-da9b-365f-21e1-877ec718c093"

#define gotSoundLib$waterprimal$aggro "abbf8ff9-58cd-b416-ede1-a91875439461"
#define gotSoundLib$waterprimal$takehit "97fb7512-d6fd-a622-52ad-111884c7791c"
#define gotSoundLib$waterprimal$attack "083c3b88-e341-8ff4-1083-bff58b42016b"
#define gotSoundLib$waterprimal$death "8e6af0e4-1c61-6355-179e-a2ff812d9a93"

#define gotSoundLib$airprimal$aggro "5c875e44-eb23-1b75-dcc8-3b47c13f2469"
#define gotSoundLib$airprimal$takehit "de19e8f6-3b7a-3ed4-2151-3f8f1239bcf8"
#define gotSoundLib$airprimal$attack "1d444a39-d2dd-b253-c424-fbd01eaf21d2"


#define gotSoundLib$target_dummy$takehit "de19e8f6-3b7a-3ed4-2151-3f8f1239bcf8"
#define gotSoundLib$target_dummy$attack "47e18f68-27cc-f790-f882-f70e752904d9"
#define gotSoundLib$target_dummy$death "a30e9deb-b73b-0d8a-f161-3c6ca9a697ff"




#define gotSoundLib$zapbot$aggro "35c275ae-66a3-0b42-3a4c-f9efa049de5e"
#define gotSoundLib$zapbot$aggro_lost "c6b08c80-eae3-4a75-f30f-d34c1b95f66e"
#define gotSoundLib$zapbot$takehit "a354f1db-dfdf-42fa-1e41-d915367d22e4"
#define gotSoundLib$zapbot$attack "f6952ece-1eba-c7b0-e960-8253d18c2c61"
#define gotSoundLib$zapbot$death "2cba8867-f1b9-a657-a12d-3629b7906314"


#define gotSoundLib$octocat$aggro "0b291275-8881-1072-6ad2-1a8a9edbc45a"
#define gotSoundLib$octocat$takehit "5af357bf-2714-d0c7-c68e-81fd7c31fa4c"
#define gotSoundLib$octocat$attack "cd62682d-1374-5372-c96f-2e22e1863350"
#define gotSoundLib$octocat$death "5f5722be-5de1-2c63-8018-aa81c77282ce"

#define gotSoundLib$servoprobe$aggro "35c275ae-66a3-0b42-3a4c-f9efa049de5e"
#define gotSoundLib$servoprobe$takehit "a354f1db-dfdf-42fa-1e41-d915367d22e4"
#define gotSoundLib$servoprobe$attack "f6952ece-1eba-c7b0-e960-8253d18c2c61"
#define gotSoundLib$servoprobe$death "2cba8867-f1b9-a657-a12d-3629b7906314"

#define gotSoundLib$leech$aggro "e539cc8a-73fd-487d-8219-7962213e0ed9"
#define gotSoundLib$leech$takehit "cfdc89c2-a976-7e76-4339-04b777b7edd8"
#define gotSoundLib$leech$attack "ff5f6d30-a926-31bf-fa95-2ee6b88fbdac"
#define gotSoundLib$leech$death "898c9cec-92d6-2102-438b-b5f575ccddd8"


#define gotSoundLib$suckerfish$aggro "ece56a9e-2fa3-9728-94a8-d3f96bf750b9"
#define gotSoundLib$suckerfish$takehit "5b451e03-141b-ac76-db22-3e2104f00d02"
#define gotSoundLib$suckerfish$attack "c3c057fb-403c-f209-0e17-29e55002cbbe"
#define gotSoundLib$suckerfish$death "0f2de2c8-c64b-0d93-bcb7-6b2b3ecfda77"



#define gotSoundLib$cluster$attack_small "dd5ed18e-9ec0-95d0-4da7-b4b6ebabe125"
#define gotSoundLib$cluster$takehit "e77d6d08-d8d6-551f-6492-ba0931f7a6ea"
#define gotSoundLib$cluster$attack "832a7dbc-d1e5-b772-3ec7-18c9144ac4a4"
#define gotSoundLib$cluster$death "9091676b-1da1-0f6e-8795-bf1a44133a69"



#define gotSoundLib$minisini$takehit "6ec47fc1-e048-4e9f-a3f3-68c23d690793"
#define gotSoundLib$minisini$attack "d526f5fb-6bde-8241-ee79-273056e61ea0"
#define gotSoundLib$minisini$death "9c095ae1-e5af-b378-e56c-395a166e37c4"

#define gotSoundLib$bespiker$aggro "deb4fd36-ce86-1c93-44dc-5cd969d19226"
#define gotSoundLib$bespiker$takehit "c01818bb-3914-d3a5-e790-529edd491388"
#define gotSoundLib$bespiker$attack "f952bef6-a8d6-57f0-57f1-40dd3591d397"
#define gotSoundLib$bespiker$death "fac57b8b-476f-bcaf-daf0-2150e4d39f6d"

#define gotSoundLib$imp$aggro "e3143506-1cc1-f457-aee9-5ab1b6501f1b"
#define gotSoundLib$imp$takehit "ed8b781b-36ae-b5bc-da8c-112d9dbf23bc"
#define gotSoundLib$imp$attack "774d8b4a-375c-de30-6948-0235d5f43e93"
#define gotSoundLib$imp$death "654506d2-1a40-f82c-8ec4-bcf01aebf4a4"

#define gotSoundLib$iceElemental$aggro "060281ff-771e-8e80-46dd-300db65bccf6"
#define gotSoundLib$iceElemental$takehit "d1e62b67-758f-71a1-bffe-a3fe5ffc07cf"
#define gotSoundLib$iceElemental$die "b4c90c98-20b8-85b5-a0e3-7129141246cd"

#define gotSoundLib$legbot$aggro "35c275ae-66a3-0b42-3a4c-f9efa049de5e"
#define gotSoundLib$legbot$takehit "a354f1db-dfdf-42fa-1e41-d915367d22e4"
#define gotSoundLib$legbot$attack "5aaaa1a3-aa19-08b8-5ec1-10bca09b0cc3"
#define gotSoundLib$legbot$death "2cba8867-f1b9-a657-a12d-3629b7906314"

#define gotSoundLib$cacodemon$aggro "e3d9f381-db30-0d41-d8b9-aacc3864e454"
#define gotSoundLib$cacodemon$takehit "6913de89-b5bf-c022-671c-9ff735d9fbc6"
#define gotSoundLib$cacodemon$attack "3135bae3-5f3e-1997-bb01-622c43774faf"
#define gotSoundLib$cacodemon$death "0609a8be-62a9-735e-fd4d-7a2002f33bbf"


#define gotSoundLib$demonDick$aggro "3823be6e-268a-bd3d-7a87-5838c915dc41"
#define gotSoundLib$demonDick$takehit "a2d9aeea-5e97-9562-c494-f47306f001d3"
#define gotSoundLib$demonDick$attack "398f13d5-c14a-d917-f7fa-6742970ed20c"
#define gotSoundLib$demonDick$death "d8a63bab-b179-ab06-bb16-78e0131eb3c9"


#define gotSoundLib$virus$aggro "853f035e-1207-01c4-cc63-7cf806596e15"
#define gotSoundLib$virus$takehit "19b92015-344b-e521-0ad2-2241cb9faf8c"
#define gotSoundLib$virus$attack "60eb0589-1e24-b057-4dce-17f91c4501e0"
#define gotSoundLib$virus$death "ae03161c-6a61-a1e8-9247-c41c7ca6e391"

#define gotSoundLib$slime$aggro "1c5e3d99-4ca4-a041-baa9-933c217d996c"
#define gotSoundLib$slime$takehit "7b6af76a-e644-1714-62b9-eabbb6491cac"
#define gotSoundLib$slime$attack "0c06e072-5a90-ff5c-e993-9983f2fd08bd"
#define gotSoundLib$slime$death "ad798ead-8267-e52c-f082-e0c30f9528ca"

#define gotSoundLib$icecrawler$aggro "9b092f60-7ca9-711f-96a7-7fa031ec521e"
#define gotSoundLib$icecrawler$takehit "f86f719d-8dff-1271-e56d-ae5b55128c8a"
#define gotSoundLib$icecrawler$attack "c26de718-785c-f9c1-54ed-5e6f85a2fc07"
#define gotSoundLib$icecrawler$death "b1b6e908-e1e0-90b4-88d6-5450b5c92977"

#define gotSoundLib$eelHorror$aggro "b9efb85e-b0bf-403a-a2be-fc962db477b4"
#define gotSoundLib$eelHorror$takehit "7966f7b6-40cb-9e56-e085-d886dd1ae73d"
#define gotSoundLib$eelHorror$attack "e747ca07-ba6f-01c0-6fc6-24297f19c6d5"
#define gotSoundLib$eelHorror$death "bf130e7e-42e6-d5fc-449a-0234481ae9ea"

#define gotSoundLib$snake$aggro "bc2fe7d9-6644-85a9-32ce-95179e9460cf"
#define gotSoundLib$snake$takehit "96bb57d2-65d1-dfdb-9216-8e3e98ec8325"
#define gotSoundLib$snake$attack "d04c5fa4-4c84-8fa7-f566-41bb16e5d52e"
#define gotSoundLib$snake$death "654a726d-56ab-31e5-fa76-34e5eeadb68b"

#define gotSoundLib$skeleton$aggro "a64a9151-970f-74c0-e6c6-dcd08da6bb46"
#define gotSoundLib$skeleton$takehit "5925a997-2650-dd7f-64e2-0a4d714a94ed"
#define gotSoundLib$skeleton$attack "eda24a53-2b1c-31f8-8c5e-878db4dd7ad4"
#define gotSoundLib$skeleton$death "07068dce-5fdd-4f4d-8a53-302b92ce21a7"

#define gotSoundLib$witch$aggro "d5afce11-0748-d852-4bcb-2d39c9246c2a"
#define gotSoundLib$witch$aggro_lost "8c193051-f148-04f2-ecee-ed2ee37fb234"
#define gotSoundLib$witch$takehit "731f8784-90e0-2e8e-cc3a-267201595d93"
#define gotSoundLib$witch$attack "89171a60-49b7-ba22-bbcb-97d61bc13464"
#define gotSoundLib$witch$death "80d441b4-243b-6036-df46-45a1254be9f4"

#define gotSoundLib$golem$aggro "923f364d-72df-bf95-5027-aaaaa9253fe5"
#define gotSoundLib$golem$takehit "cdf1ad10-7768-87c7-0ee3-2b978bef597e"
#define gotSoundLib$golem$attack "ab6b782b-a0c6-45f9-63b3-05c9025ddac4"
#define gotSoundLib$golem$death "ac8389b3-80a9-2164-fcde-df33e18c130b"

#define gotSoundLib$residue$aggro "353af8f8-6129-e393-3d50-dd3b7866d52c"
#define gotSoundLib$residue$takehit "8e5efd51-2eb7-505e-8e4e-3f6fafaa48de"
#define gotSoundLib$residue$attack "baaa5950-b972-0e97-11ec-96cf1568b2b3"
#define gotSoundLib$residue$death "4d3c5a7b-be42-b92b-6b19-7f04510db479"


#define gotSoundLib$humanMale$aggro "cbbf5234-24d4-692d-3470-47a2f3e8bc42"
#define gotSoundLib$humanMale$takehit "ea2cf924-1ad9-2421-013f-a916205eba95"
#define gotSoundLib$humanMale$attack "aec5cd63-1756-9c7c-671f-018976e53989"
#define gotSoundLib$humanMale$death "c1047f61-db16-2224-8c9c-c7aa610bac0c"

#define gotSoundLib$gnawer$aggro "01e17fb6-f116-53b2-d357-ded2cb593f22"
#define gotSoundLib$gnawer$takehit "f12d384c-4c15-a34d-3962-964968a32ff3"
#define gotSoundLib$gnawer$attack "6f68db90-7acc-f25d-eb58-66ca56ddadb6"
#define gotSoundLib$gnawer$death "7f506589-9062-8f4f-4a2d-600ff612b672"

#define gotSoundLib$humanTiger$aggro "104853d3-3efb-d543-105e-e2427ce7b805"
#define gotSoundLib$humanTiger$aggro_lost "0de57c59-cb6f-7c59-55dc-e26cf25779cb"
#define gotSoundLib$humanTiger$takehit "d10cfa51-699d-2ce8-9ce5-4ed9dd4f1843"
#define gotSoundLib$humanTiger$attack "13f825a1-3ba7-a49d-9986-f4a8fb5c37b1"
#define gotSoundLib$humanTiger$death "48422e50-f207-1973-0ea4-7ce8fabb6eb6"

#define gotSoundLib$tentacleTiger$aggro "80dfd548-1f14-f04f-4f61-0d26c90a19bf"
#define gotSoundLib$tentacleTiger$takehit "5834444b-8d12-0a91-bf1b-435b184088eb"
#define gotSoundLib$tentacleTiger$attack "a721e5cf-42b6-1060-7dd4-65d69584e9c6"
#define gotSoundLib$tentacleTiger$death "0dd26453-4148-bbc1-7403-3da726914723"

#define gotSoundLib$boglasher$aggro "6b53ba91-3aa8-3e90-3bc2-7063520ce8e2"
#define gotSoundLib$boglasher$takehit "90934dde-7e10-89e2-404f-db9e1f829094"
#define gotSoundLib$boglasher$attack "e442ab54-aa9f-c42f-0646-3c034a0abbcf"
#define gotSoundLib$boglasher$death "c6b08c80-eae3-4a75-f30f-d34c1b95f66e"

#define gotSoundLib$shambler$aggro "032f462d-437e-72fc-0b91-387f57951e59"
#define gotSoundLib$shambler$takehit "d6f195c2-3d23-a2ad-f95b-876ef28ba2d7"
#define gotSoundLib$shambler$attack "2eccdd2b-0869-19e3-e628-fc27585df8c6"
#define gotSoundLib$shambler$death "846c425d-3284-e055-4166-8de781c1a0cf"

#define gotSoundLib$hand$aggro "9ac32e2d-7d22-c08e-01f7-839f83be0fd5"
#define gotSoundLib$hand$takehit "3d5ba4f0-90aa-77bb-8aca-d5d819677867"
#define gotSoundLib$hand$attack "d72f822e-1790-7d68-5653-b01f0768f009"
#define gotSoundLib$hand$death "55fc591a-e551-bdc8-0011-ad5db9c25526"


#define gotSoundLib$quadropus$aggro "7313b7bd-864d-75e5-b309-01531cbd7591"
#define gotSoundLib$quadropus$takehit "f322a55c-8f4e-d619-0ef6-57456c4c42a4"
#define gotSoundLib$quadropus$attack "2ae85936-166e-ceee-6348-a9eae5b05c58"
#define gotSoundLib$quadropus$death "e8b0c58c-d88b-5a86-a297-193feedb9abe"


#define gotSoundLib$recordkeeper$aggro "aa4b75f2-6ff5-65a9-222b-f231d7ba0ae0"
#define gotSoundLib$recordkeeper$takehit "232597be-5a1e-0b77-c039-be9bb88b0908"
#define gotSoundLib$recordkeeper$attack "0a6f4171-69ac-5026-238e-63e2229c79d3"
#define gotSoundLib$recordkeeper$death "885699bd-7f04-a5a5-e404-251bf268444e"


#define gotSoundLib$globber$aggro "d0f2ea8b-188b-c2fc-c670-d0bdeaf80dae"
#define gotSoundLib$globber$takehit "90934dde-7e10-89e2-404f-db9e1f829094"
#define gotSoundLib$globber$attack "e442ab54-aa9f-c42f-0646-3c034a0abbcf"
#define gotSoundLib$globber$death "90934dde-7e10-89e2-404f-db9e1f829094"


#define gotSoundLib$worm$aggro "cc1c23d6-9931-67be-3aaa-0fe8c4bc3c3f"
#define gotSoundLib$worm$takehit "f12d384c-4c15-a34d-3962-964968a32ff3"
#define gotSoundLib$worm$attack "d67886aa-6ea8-0409-2742-aeca3eb31d21"

#define gotSoundLib$shocktacle$takehit "f12d384c-4c15-a34d-3962-964968a32ff3"
#define gotSoundLib$shocktacle$attack "d67886aa-6ea8-0409-2742-aeca3eb31d21"
#define gotSoundLib$shocktacle$death "398f13d5-c14a-d917-f7fa-6742970ed20c"

#define gotSoundLib$phantom$aggro "a78af3a7-a841-0a5d-0d7d-f75e268ed235"
#define gotSoundLib$phantom$takehit "cad61af4-a1cd-2221-1bef-9cec88cf0078"
#define gotSoundLib$phantom$attack "2b2998a4-99d1-aff1-370d-eecc0363d6f7"
#define gotSoundLib$phantom$death "ebe2edf7-0785-78bb-f52d-b6718a485e1e"


#define gotSoundLib$lotus$aggro "58f34e31-6c69-1040-6d01-028aa6f8106a"
#define gotSoundLib$lotus$takehit "dacb3254-f455-0c4f-4632-5cd237b08d3e"
#define gotSoundLib$lotus$attack "6d71f5aa-ab47-f2b8-ece9-fff9fada7057"
#define gotSoundLib$lotus$death "93601993-053d-7696-d782-debab3e28e34"


#define gotSoundLib$mushroom$loop "1fc5e30a-1036-7942-95b0-7d696c0c5f88"
#define gotSoundLib$mushroom$takehit "f615123a-61ce-41d8-5d1f-5caf9cd6ad33"
#define gotSoundLib$mushroom$attack "fbde75c0-b744-dab3-d140-4a6cf8f74705"
#define gotSoundLib$mushroom$death "b1c84e60-fcb5-0575-291d-6bf9e1c6ac13"


#define gotSoundLib$tmfiend$spawn "4bb9ca16-a6a7-3662-41b7-2076ae3f7385"
#define gotSoundLib$tmfiend$takehit "a0db0d96-21d8-34d3-39a7-adeec0b6b6db"
#define gotSoundLib$tmfiend$attack "480052ef-34b5-cfcf-d3e2-bd1aff139819"
#define gotSoundLib$tmfiend$death "e2bae45a-24f6-894f-01c3-bf3090096b3f"

#define gotSoundLib$assistacle$takehit "ca47de64-fa72-c394-7b53-d126c9f46237"
#define gotSoundLib$assistacle$attack "1ed6c159-9b6b-513f-757f-b0187cd937cd"
#define gotSoundLib$assistacle$death "d78b59a0-4f91-3d82-6ec6-9767da63a069"




#define gotSoundLib$spanks (list)"f8dad0f8-2ffc-ccbf-d115-8a8808722690" + "dcbfcb36-b84d-809f-c07b-cb0ab61d3cd8" + "76716856-edc6-6d7c-dbc9-7ec23723c6f6"
#define gotSoundLib$squish (list)"b0df139c-4a16-ea66-9596-e066719ea334" + "63be71de-c17e-5aa7-a568-9e41e4cbd2c9" + "b82ed554-a4e3-cd38-2306-c3b114ec0bfc"



#endif
